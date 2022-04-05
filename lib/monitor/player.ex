defmodule Monitor.Player do
  use GenServer
  require Logger

  @minute :timer.seconds(60)
  @hour   :timer.seconds(3600)

  ##### clientside api ########################################################

  def start_link([name, prv, puuid]) do
    GenServer.start_link(__MODULE__, [name, prv, puuid])
  end

  def child_spec([name, prv, puuid]) do
    %{id: puuid, start: {__MODULE__, :start_link, [[name, prv, puuid]]}}
  end

  ##### server callbacks ######################################################

  def init([name, prv, puuid]) do
    schedule_sweep(:minute_interval)
    schedule_sweep(:hour_window)

    summoner = %{
      last_mid: "",
      name: name,
      prv: prv,
      puuid: puuid
    }

    {:ok, summoner}
  end

  def handle_info(:minute_interval, summoner) do
    case new_match?(summoner) do
      nil ->
        {:noreply, summoner}
      latest_match ->
        if summoner.last_mid == "" do
          {:noreply, %{summoner | last_mid: latest_match}}
        else
          Logger.info "Summoner #{summoner.name} completed match #{latest_match}"
          {:noreply, %{summoner | last_mid: latest_match}}
        end
    end
  end

  def handle_info(:hour_window, _summoner) do
    exit :shutdown
  end

  ##### helper functions ######################################################

  defp schedule_sweep(:minute_interval) do
    Process.send_after(self(), :minute_interval, @minute)
  end
  
  defp schedule_sweep(:hour_window) do
    Process.send_after(self(), :hour_window, @hour)
  end

  defp new_match?(summoner) do
    latest_match = hd(Monitor.Limiter.json_of(:for_match_id, summoner))
    schedule_sweep(:minute_interval)
    
    if summoner.last_mid == latest_match do nil else latest_match end
  end
end
