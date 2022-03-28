defmodule Monitor.Limiter do
  @moduledoc """
  Module Monitor.Limiter manages both the GET requests made to the Riot
  Developer API in addition to keeping the rate of those requests within the
  interval of the developer's enforced rate limits, i.e. 20 requests per second
  & 100 requests per two minutes.
  """
  @apikey Application.fetch_env!(:monitor, :apikey)

  @urlmat Application.fetch_env!(:monitor, :urlmat)
  @urlsum Application.fetch_env!(:monitor, :urlsum)

  @fine_frame :timer.seconds(1)
  @leaky_full 10

  @coarse_frame :timer.seconds(12)
  @overflow_full 10


  @doc """
  Function json_of/2 sends a GET request to the Riot Developer API via Elixir's
  HTTP client HTTPoison if the request can be made within the specified limits,
  for which the response is decoded & returned.

  parameters___________________________________________________________________
  request
  an atom specifying what kind of path must be assembled & hence what kind of
  request is being made

  summoner
  a hash map containing all the requisite fields necessary for the respective
  GET request to the developer API

  mid
  an optional parameter containing the match id when match data is requested
  """
  def json_of(request, summoner, mid \\ "") do
    case limit_check() do

      # If the request is allowed, request is made with the appropriate path.
      {:allow, _count} ->
        endpoint = url_of(request, summoner, mid)

        # If the request is successful (status code 200), the body is decoded.
        # Otherwise, an exception is made
        case HTTPoison.get(endpoint) do
          {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
            body |> JSON.decode!
          _ ->
            raise "Invalid API request"
        end

      # If denied, a call is made to wait/0 before making a tail-recursive call
      # to itself to loop until requests are allowed.
      {:deny, _limit} ->
        wait()
        json_of(request, summoner, mid)
    end
  end

  @doc """
  Function url_of/2 assembles the relevant pathways for GET requests to Riot
  Developer API.

  Function parameters are equivalent to  & share the same functionality as
  those of function json_of/2 above. Refer to json_of/2's documentation for
  more details.

  Note that the first pathway only requires a summoner's specific platform
  routing value (prv), while the pathways respective to match GET requests
  require regional routing values (rrv) & calls are made to an appropriate
  helper function to attain those.
  """
  def url_of(request, summoner, mid \\ "") do
    case request do

      # Pathway to get a summoner's puuid; specified GET request for a
      # summoner's data via their summoner name
      :for_puuid ->
        "https://#{summoner.prv}#{@urlsum}#{summoner.name}?api_key=#{@apikey}"

      # Pathway to get a list of match ids by puuid
      :for_match_id ->
        "https://#{rrv?(summoner.prv)}#{@urlmat}by-puuid/#{summoner.puuid}/ids?start=0&count=5&api_key=#{@apikey}"

      # Pathway to get all relevant match data including its participants by
      # match id.
      :for_summoners ->
        "https://#{rrv?(summoner.prv)}#{@urlmat}#{mid}?api_key=#{@apikey}"

      _              ->
        raise "Invalid URL"
    end
  end

  @doc """
  Function rrv?/1 takes in a platform routing value (prv) from the command
  line, formats the string by making a call to a helper function, & returns its
  respective regional routing value (rrv). If none, an exception is raised.

  parameters___________________________________________________________________
  prv
  a string representing a summoner's platform routing value taken from the
  user's command line input
  """
  def rrv?(prv) do
    case format(prv) do
      "br1"  -> "americas"
      "la1"  -> "americas"
      "la2"  -> "americas"
      "na1"  -> "americas"
      "jp1"  -> "asia"
      "kr"   -> "asia"
      "eun1" -> "europe"
      "euw1" -> "europe"
      "ru"   -> "europe"
      "tr1"  -> "europe"
      _      -> raise "Valid regions:
                  br1, eun1, euw1, jp1, kr, la1, la2, na1, ru, tr1"
    end
  end

  @doc """
  Function format/1 is a helper function that takes in a platform routing value
  (prv) from the command line & formats the string by removing all leading &
  trailing whitespaces & converts all characters to lowercase.

  parameters___________________________________________________________________
  prv
  a string representing a summoner's platform routing value taken from the
  user's command line input
  """
  def format(prv) do
    prv |> String.trim()
        |> String.downcase()
  end


  # """
  # Private function limit_check/0 keeps all incoming GET requests to the
  # developer API within respective enforced limits by utilizing external
  # dependency rate-limiter Hammer.
  #
  # No parameters are necessary to perform this function call.
  # """

  defp limit_check() do

    # Here the first bucket limits ten requests per second.
    case Hammer.check_rate("ratelimit_leaky", @fine_frame, @leaky_full) do

      # If these requests are within allowable limits, it is then passed onto a
      # second bucket which limits requests to ten per twelve seconds.
      {:allow, _count} ->
        Hammer.check_rate("overflow", @coarse_frame, @overflow_full)

      # If neither bucket have free tokens for allowable actions/requests,
      # then the flow of requests are temporarily rate-limited & thus denied.
      {:deny, limit} ->
        {:deny, limit}
    end
  end

  # """
  # Function wait/0 puts to sleep those processes whose GET requests to the
  # developer API were denied by the rate-limiter until one of the buckets
  # utilized in function limit_check/0 frees up more tokens for allowable
  # actions accordingly.
  #
  # No parameters are necessary to perform this function call
  # """
  defp wait() do

    # Pattern matching is used to extract from the return values of
    # Hammer.inspect_bucket/3 the ms_to_next_bucket for both buckets.
    {{:ok, {_, _, leftover_leaky, _, _}},{:ok, {_, _, leftoverflow, _, _}}} =
      {
        Hammer.inspect_bucket("ratelimit_leaky", @fine_frame, @leaky_full),
        Hammer.inspect_bucket("overflow", @coarse_frame, @overflow_full)
      }

    # The two values are compared & the process is put to sleep for however
    # long the last bucket frees up tokens.
    if leftover_leaky < leftoverflow do
      :timer.sleep(leftoverflow)
    else
      :timer.sleep(leftover_leaky)
    end
  end

end
