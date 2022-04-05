defmodule Monitor do

  def summoner(summoner_name, region) do
    Monitor.Limiter.rrv?(region)

    summoner = %{
      name: summoner_name,
      prv: Monitor.Limiter.format(region),
      puuid: ""
    }
    puuid = Monitor.Limiter.json_of(:for_puuid, summoner)["puuid"]
    summoner = %{summoner | puuid: puuid}

    summoners = :for_match_id
                |> Monitor.Limiter.json_of(summoner)
                |> Task.async_stream(&Monitor.Limiter.json_of(:for_summoners, summoner, &1))
                |> Enum.map(fn({:ok, body}) -> body end)
                |> Enum.map(&((&1)["info"]["participants"]))
                |> List.flatten
                |> Enum.map(fn p ->
                               %{
                                 name: p["summonerName"],
                                 prv: summoner.prv,
                                 puuid: p["puuid"]
                               }
                            end)
                |> Enum.uniq

    monitored = summoners
                |> Enum.map(fn p -> {
                                      Monitor.Player,
                                      [p.name, p.prv, p.puuid]
                                    }
                            end)
    Supervisor.start_link(monitored, [strategy: :one_for_one])

    Enum.map(summoners, & &1.name)
  end
end
