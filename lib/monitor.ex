defmodule Monitor do
@moduledoc """
Primary application module for Blitz Elixir Project.
"""

  @doc """
  Function summon/2 makes all respective GET requests to the Riot Developer API
  as necessitated from the command line input, parse the responses, & get a
  list of all summoners & their corresonding puuids. Each summoner is linked as
  a new Player process to be supervised before a list of all participant
  summoners is returned.

  parameters___________________________________________________________________
  summoner_name
  summoner name string from command line

  region
  platform routing value from command line
  """

  #  Example:
  # iex(1)> Monitor.summoner("Thaiitea", "    NA1         ")
  # ["Happyhouse", "ßaÇøN", "meatloaf029", "w1nd1g0o", "guizm0bong0",
  # "Joofysticks", "sternbaby", "ThaiiTea", "Slow Bugs", "Feveredregent", "Linukz",
  # "jugoat", "KotKrot12", "Zevy", "AyMikey", "DaHumptyHump", "A FELLOW N W0RD",
  # "The Golden Chef ", "KrisWu20xx", "KaynHome", "Hamzah", "GNuttyy",
  # "Littlebear9277", "Feras", "PureGain", "BigANDBubbly", "culvz chan",
  # "autofillcantsupp", "Davicy", "Solsiestic", "Pampara", "Winnerfield",
  # "emptysjl", "Slyven", "Jhíń ń Tóńíć", "RiceBlunt", "andyrew1987",
  # "Plascenta Juice", "cmyles2k", "NLuv", "Mr Middletits", "HOLDupIGOTthiz",
  # "II12SQUISHY12II", "sodymni", "Iché", "brahms"]
  #
  # 14:26:30.968 [info]  Summoner w1nd1g0o completed match NA1_4259055135
  # 14:28:32.439 [info]  Summoner sternbaby completed match NA1_4259054771
  #
  # ...
  #
  # 15:18:47.729 [info]  Summoner Slow Bugs completed match NA1_4259100112
  # 15:18:48.559 [info]  Summoner ThaiiTea completed match NA1_4259100112
  # ** (EXIT from #PID<0.278.0>) shell process exited with reason: shutdown
  def summoner(summoner_name, region) do

    # Checks if input platform routing value is valid
    Monitor.Limiter.rrv?(region)

    # Input summoner as a hash map containing its name, platform routing value,
    # & player universally unique identifier
    summoner = %{
      name: summoner_name,
      prv: Monitor.Limiter.format(region),
      puuid: ""
    }
    puuid = Monitor.Limiter.json_of(:for_puuid, summoner)["puuid"]
    summoner = %{summoner | puuid: puuid}

    # First attain a list of five most recent match ids
    summoners = :for_match_id
                |> Monitor.Limiter.json_of(summoner)

                # Use a stream of asynchronous tasks to get match data for all
                # five of said matches, then parse the responses from match
                # data to attain summoner names & puuids
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

                # Removes duplicate summoners from list, e.g. summoner from
                # command line will appear five times in the list given that
                # they have participated in all previous five matches
                |> Enum.uniq

    # List of Player tuples to be supervised with the relevant specifications
    # for initialization. Supervision strategy is one-for-one, this process
    # being the only parent & each summoner child process need be restarted in
    # order to continue monitoring until the hour window is over
    monitored = summoners
                |> Enum.map(fn p -> {
                                      Monitor.Player,
                                      [p.name, p.prv, p.puuid]
                                    }
                            end)
    Supervisor.start_link(monitored, [strategy: :one_for_one])

    # List of summoner names returned
    Enum.map(summoners, & &1.name)
  end
end
