# Monitor

## Instructions

1. Configure your personal API key in `config.exs`.
2. After you switch into the `monitor` directory in the terminal, run `mix deps.get` to get all external dependencies necessary to run the application.
3. To run the application, run `iex -S mix` & once you're in the REPL, execute `Monitor.summon("<valid summoner>", "<valid region>"`, e.g. `Monitor.summon("theJ0YYY", "  NA1")`. 

To run ExUnit tests for Monitor, run `mix test --trace` in the terminal outside `iex`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `monitor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:monitor, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/monitor>.

