# Monitor

## Instructions

1. Configure your personal API key in `config.exs`.
2. After you switch into the `monitor` directory in the terminal, run `mix deps.get` 
   to get all external dependencies necessary to run the application.
3. To run the application, run `iex -S mix` to generate the application & once you're 
   in the REPL, execute 
   ```elixir
   Monitor.summoner("<valid summoner>", "<valid region>")
e.g. `Monitor.summoner("theJ0YYY", "  NA1")`. 

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
4. (03/27/22) Considering the original user input summoner may also be playing
   matches in real time, the pool of all monitored summoners this summoner has
   played with in the last five matches would be constantly changing as the original
   summoner completes new matches over time not even just over the course of an hour
   but over an indefinite amount of time & possibly every summoner played with in
   the last seven, ten, or fifteen matches. Such a pool of summoners would have to be
   dynamically supervised so that when this "root" summoner completes a match, new
   summoners could be pooled in while old summoners could be pulled out possibly 
   with an ETS cache to keep track?
5. (03/25/22) The rate-limiter that was originally implemented used an ETS cache
   table & erlang's built in atomic counter to keep track of the number of requests.
   When the OTP task scheduling mechanism was transferred over to the Monitor.Player
   module, I had also considered using an ETS cache to keep track of the summoner
   worker's data & keep track of played matches everytime the module sent itself
   messages every minute. I would imagine that using an ETS cache would be more
   optimal with respect to the application's overall complexity since all operations
   for using the ETS cache is in constant time, as opposed to its current 
   implementation utilizing the GenServer state but found myself a bit pressed for
   time to adapt it & have it compatible with other modules. This hit me hard in the
   sense that it pained me to realize the hard way of why the software development
   maxim of "CLOSED TO MODIFICATION, OPEN TO EXTENSION" is super important.
6. (04/06/22) Rereading & reviewing Elixir texts had me chance upon this excerpt: "?
   is often used to indicate a function that returns either true or false" so I 
   renamed the function that returns the regional routing value from rrv?/1 to rrv/1.
   Also removed the majority of my documentation because I had realized that my
   intended audience are tenured developers who are already familiar with the
   language, not students or people I'm tutoring with whom I am sharing my code with.
   I am sure there are many other conventions that my code has yet to follow due to
   me being very new to the language but as always I'm still learning & there's
   always room for development. 
