defmodule Monitor.Player do
  @moduledoc """
  Module Monitor.Player monitors some respective summoner that the GenServer is
  initially specified to for new matches & utilizes OTP to schedule this task
  every single minute for the next hour. If this summoner manages to complete a
  match within this interval, the match id is thus logged onto the console.
  """
  use GenServer
  require Logger

  @minute :timer.seconds(60)
  @hour   :timer.seconds(3600)


  ##### clientside api ########################################################

  @doc """
  start_link/1 starts the Player GenServer by calling GenServer.start_link/3
  with the current module as the first parameter & a list of its respective
  summoner's stats.

  parameters___________________________________________________________________
  name
  summoner name string

  prv
  platform routing value string

  puuid
  player universally unique identifier string
  """
  def start_link([name, prv, puuid]) do
    GenServer.start_link(__MODULE__, [name, prv, puuid])
  end

  @doc """
  child_spec/1 builds the specification of this child server to be supervised,
  specifying that the puuid of the summoner serves as the unique identifier per
  Player server.

  Function parameter is that of the same as start_link/1
  """
  def child_spec([name, prv, puuid]) do
    %{id: puuid, start: {__MODULE__, :start_link, [[name, prv, puuid]]}}
  end


  ##### server callbacks ######################################################

  @doc """
  init/1 schedules two asynchronous tasks then takes the child specifications
  of the summoner to initialize the overall server state as a hashmap with all
  the parameter list entries in addition to another key utilized for keeping
  track of each summoner's most recent match.
  """
  def init([name, prv, puuid]) do

    # Initial asynchronous calls to the module are made to start both tasks of
    # monitoring new matches every minute & shutting down the server after an
    # hour, respectively.
    schedule(:minute_interval)
    schedule(:hour_window)

    summoner = %{
      last_mid: "",
      name: name,
      prv: prv,
      puuid: puuid
    }

    {:ok, summoner}
  end

  @doc """
  handle_info/2 function when pattern-matched to the :minute_interval message
  by the module makes a call to helper function new_match?/1 to determine
  whether the summoner has completed a new match.

  parameters___________________________________________________________________
  :minute_interval
  atom message specifying to the module how to handle this particular
  asynchronous call pattern-matched said message

  summoner
  hashmap server state containing keys specifying the match id of the most
  recent match, summoner name, platform routing value (prv), & puuid
  """
  def handle_info(:minute_interval, summoner) do
    case new_match?(summoner) do

      # If no new match has been played, another asynchronous call is scheduled
      # to be made the next minute.
      nil ->
        schedule(:minute_interval)
        {:noreply, summoner}

      # If a new match has been played, log said match id onto console &
      # schedule another asynchronous call to be made the following minute &
      # update the server state.
      # Note that since the initial state to last_mid is the empty string, once
      # a call is made to update it, it does not need to be logged.
      latest_match ->
        if summoner.last_mid == "" do
          schedule(:minute_interval)
          {:noreply, %{summoner | last_mid: latest_match}}

        else
          Logger.info "Summoner #{summoner.name} completed match #{latest_match}"

          schedule(:minute_interval)
          {:noreply, %{summoner | last_mid: latest_match}}
        end
    end
  end

  # """
  # handle_info/2 function when pattern-matched to the :hour_window message by
  # the module shuts down the entire monitoring process after an hour
  #
  # parameters_________________________________________________________________
  # :hour_window
  # atom message specifying to the module how to handle this particular
  # asynchronous call pattern-matched said message
  # """
  def handle_info(:hour_window, _summoner) do
    exit :normal
  end


  ##### helper functions ######################################################

  # Delayed call to module after a minute with message :minute_interval
  defp schedule(:minute_interval) do
    Process.send_after(self(), :minute_interval, @minute)
  end

  # Delayed call to module after an hour with message :hour_window
  defp schedule(:hour_window) do
    Process.send_after(self(), :hour_window, @hour)
  end

  # Helper function new_match?/1 makes a GET request to the developer API to
  # get the match id. Returns nil no new match, returns the latest match id
  # otherwise.
  defp new_match?(summoner) do
    latest_match = hd(Monitor.Limiter.json_of(:for_match_id, summoner))

    if summoner.last_mid == latest_match do nil else latest_match end
  end
end
