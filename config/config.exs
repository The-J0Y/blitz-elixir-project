import Config

config  :monitor,
  apikey: "_____-________-____-____-____-____________",

  urlmat: ".api.riotgames.com/lol/match/v5/matches/",
  urlsum: ".api.riotgames.com/lol/summoner/v4/summoners/by-name/"

config :hammer,
  backend: {Hammer.Backend.ETS,
            [expiry_ms: 60_000 * 60 * 4,
             cleanup_interval_ms: 60_000 * 10]}
