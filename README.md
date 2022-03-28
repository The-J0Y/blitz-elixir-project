# Monitor

## Instructions

1. Configure your personal API key in `config.exs`.
2. After you switch into the `monitor` directory in the terminal, run `mix deps.get` 
   to get all external dependencies necessary to run the application.
3. To run the application, run `iex -S mix` & once you're in the REPL, execute 
   ```elixir
   Monitor.summon("<valid summoner>", "<valid region>")
e.g. `Monitor.summon("theJ0YYY", "  NA1")`. 

To run ExUnit tests for Monitor, run `mix test --trace` in the terminal outside `iex`.

## Personal Observations & Notes

1. (03/24/22) Learned the hard way that writing your own rate limiter from scratch 
   whose purpose is secondary in this project is akin to writing one's own parser or 
   JSON decoder from scratch in order to write a weather tracking application, i.e. 
   an unnecessarily complex disaster. The OTP task scheduler of this original rate 
   limiter was salvaged to become the asychnronous scheduling mechanism for the 
   Monitor.Player worker module.
2. (03/27/22) `Logger.debug` was not only helpful in just tracing code execution, but 
   also in the observation of its temporal flow of all requests made by summoner 
   workers when I was testing monitoring new matches over the course of an hour. For 
   example, I originally had a different algorithm implemented for function 
   Monitor.Limiter.wait() which puts a process to sleep if the number of requests 
   made has reached a certain threshhold. With this original algorithm, I had 
   observed that requests were made from workers in alternating periods of heavy 
   bursts & inactivity, occasionally resulting in bursts of crashes as well. After
   slightly modifying the wait() algorithm, I noticed that requests were made in a
   steady, constant stream, for which if & when crashes occurred, they occurred 
   sparingly & also in isolation as opposed to occurring in dense bursts. This helped
   illustrate to me the importance of temporal behavior/distribution when it concerns
   reliability & fault-tolerance.
3. (03/26/22) Doing this project definitely brings up overtones of past struggles in
   upper div data structures & compiler construction, specifically how there is a 
   fine-lined nuanced relationship between the abstraction of how you want flow/data 
   to be structured (i.e. imagine diagrams on a whiteboard) & how it is subsequently
   implementated within the parameters & boundaries of the language it is expressed
   in (i.e. its "architecture", if you will). For example, after my from-scratch
   rate-limiter was scrapped, I originally had the Monitor.Limiter module merged 
   with the Monitor module but had opted to put the majority of the Monitor.Limiter
   functionality in a separate module (of which you can still see some hastily 
   separated messy traces in Monitor such as the data transformation from command
   line & the manual JSON parsing). On paper, there shouldn't be any problems with
   having all that functionality in the parent, but in implementation the code
   became ultra convoluted for which a simpler solution would be just to put it in
   a separate module & have the supervised workers made calls to that instead of the
   parent.

