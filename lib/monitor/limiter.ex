defmodule Monitor.Limiter do
  @apikey Application.fetch_env!(:monitor, :apikey)
  @urlmat Application.fetch_env!(:monitor, :urlmat)
  @urlsum Application.fetch_env!(:monitor, :urlsum)

  @fine_frame :timer.seconds(1)
  @leaky_full 10
  @coarse_frame :timer.seconds(12)
  @overflow_full 10

  def json_of(request, summoner, mid \\ "") do
    case limit_check() do
    
      {:allow, _count} ->
        endpoint = url_of(request, summoner, mid)

        case HTTPoison.get(endpoint) do
          {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
            body |> JSON.decode!
          _ ->
            raise "Invalid API request"
        end

      {:deny, _limit} ->
        wait()
        json_of(request, summoner, mid)
    end
  end

  def url_of(request, summoner, mid \\ "") do
    case request do
      :for_puuid ->
        "https://#{summoner.prv}#{@urlsum}#{summoner.name}?api_key=#{@apikey}"
      :for_match_id ->
        "https://#{rrv!(summoner.prv)}#{@urlmat}by-puuid/#{summoner.puuid}/ids?start=0&count=5&api_key=#{@apikey}"
      :for_summoners ->
        "https://#{rrv!(summoner.prv)}#{@urlmat}#{mid}?api_key=#{@apikey}"
      _              ->
        raise "Invalid URL"
    end
  end

  def rrv!(prv) do
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

  def format(prv) do
    prv |> String.trim()
        |> String.downcase()
  end

  defp limit_check() do
    case Hammer.check_rate("ratelimit_leaky", @fine_frame, @leaky_full) do
      {:allow, _count} ->
        Hammer.check_rate("overflow", @coarse_frame, @overflow_full)
      {:deny, limit} ->
        {:deny, limit}
    end
  end

  defp wait() do
    {{:ok, {_, _, leftover_leaky, _, _}},{:ok, {_, _, leftoverflow, _, _}}} =
      {
        Hammer.inspect_bucket("ratelimit_leaky", @fine_frame, @leaky_full),
        Hammer.inspect_bucket("overflow", @coarse_frame, @overflow_full)
      }
      
    if leftover_leaky < leftoverflow do
      :timer.sleep(leftoverflow)
    else
      :timer.sleep(leftover_leaky)
    end
  end
end
