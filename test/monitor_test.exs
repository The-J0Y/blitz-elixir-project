defmodule MonitorTest do
  use ExUnit.Case
  doctest Monitor

  describe "user input platform routing value & corresponding matches" do
    test "whitespace & case do not matter with prv input" do
      assert Monitor.Limiter.rrv("             eUw1 ") == "europe"
    end
    test "list of matches received from GET request should be same region" do
      summoner = %{name: "theJ0YYY", prv: "na1", puuid: ""}
      puuid = Monitor.Limiter.json_of(:for_puuid, summoner)["puuid"]
      summoner = %{summoner | puuid: puuid}

      mid = hd(Monitor.Limiter.json_of(:for_match_id, summoner))
      region = hd(String.split(mid,"_"))

      assert String.upcase(summoner.prv) == region
    end
  end

  describe "returned list of summoners has unique properties" do
    test "list should have at the very least ten summoners" do
      num = Enum.count(Monitor.summoner("theJ0YYY", "na1"))
      assert num >= 10
    end
    test "no duplicates of user input summoner" do
      count = Enum.count(Monitor.summoner("theJ0YYY", "na1"), & &1 == "theJ0YYY")
      assert count == 1
    end
  end
end
