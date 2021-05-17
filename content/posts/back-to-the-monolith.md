---
title: Going back to the Monolith well
subtitle: A plea to go back to do what we should always have done but to do it right this time
draft: false
date: 2020-02-20T23:30:00-03:00
tags:
     - monolith
     - oop
     - software-architecture
     - microservices
---

We were extremely warned about the dangers of microservices, but we implement them anyway. Now, we are slowly realizing that we should have never, ever, abandoned the monolith. Our multiple failures at microservices probably speak of two things, (1) we probably lack the workforce and proper Ops team to carry this effort onward and (2) we probably could have solved our problem without them anyway. Note that I'm saying that microservices are fine. I'm also saying that they might have not been for us.

We should not feel sorry though. We are craftsmen, professionals, people that must be on top of every new trend or tech. It's normal we feel the drive to try every shiny new thing under the sun. I do that myself. But is a good thing when learn from our mistakes and correct them as soon as possible. And this is what this post is about.

I'm grateful to microservices in the sense that they helped us see more clearly the boundaries and different responsibilities in our business, and to separate individuals to work in in those and own them. What I'm not grateful of is the fact of defining those boundaries behind a TCP connection and poorly typed content-types, and all the implications that come with it. We should have kept our boundaries, for sure, but in the reliable and fast realm of random access memory.

{{< tweet 1154067788828434433 >}}

Let's think for a second. We really needed to make different applications to communicate over TCP to realize that team autonomy and separation of concerns was a good thing? If breaking down problems into smaller units and give certain individuals ownership of the implemented solution is *the* requirement of microservices, then we should have been doing them since the 70's.

Truth is, OOP already solved these problems. I think we just forgot how to use it to our benefit. What is better? A RPC HTTP over TCP endpoint that takes a json payload and process it with some notorious latency and possibility of network error, or an interface (with the corresponding implementation) that names the action in a meaningful way, documents it and takes a well defined data class as the argument so you can have a deterministic in-memory result?

I know, at some point we got scared of having many of those in a single place. We got scared that could be overwhelming for new developers to familiarize with all the services in a huge codebase. But truth is that, as in microservices, you don't need to know all the details. Remember? This is what abstraction in OOP means. Implementation details can be hidden from us as long as we expose an interface that explains itself well and does the job it says it does. In microservices, does the booking app team knows or has to know every detail of the billing app? Of course not! They just know they have a `pay` endpoint that takes some money and a booking id. Why not implementing both "apps" in different folders of the same codebase, throw away the network issues and enjoy calling routines in memory? Isn't that much simpler? Worried about boundaries may not be respected? Nothing that a good CI config with a `CODEOWNERS` file feature cannot solve.

Just a quick side note here. I think we abused so much of frameworks that we took architecture for granted, and that made us fail at monoliths. With frameworks, we didn't need to learn how to bootstrap and wire up and app by ourselves, by pulling the required pieces. We didn't have to learn how to integrate different modules and make them work together, which is a crucial skill for a developer. I think that's the fundamental piece that is missing when a developer is faced with the task of developing in a modular way: they know how to create a new class and put some code there. What they don't know, is how to wire them up together to make them work in harmony with others.

I truly think there is a case for microservices, and that's when you need to get the most of a certain stack. Netflix might need to switch their video encoders from Go to Rust to avoid the overhead of GC spikes and save millions in processing costs because, well, they are Netflix. But for most of us, mere mortals followers of the trends that knock our doors, microservices are not needed. The complexity they introduce is far more than the problems they solve for our small use case.

We need to go back to OOP and its best practices. To create modular systems, not for the sake of reusability (as it was heavily sold in the years gone by), but for the sake of maintainability. Each module should be autonomous, and communication between them should not be coupled. This is achieved with known techniques, like a solid translation/anticorruption layer. You say "Oh what a burden to write all that translation logic!" Bro, you were doing it with microservices already, parsing your json payloads to meaningful objects. Maybe you were luckier and used *protobufs* instead, but the mapping/translation was still there, just made a bit easier by an automated tool.

So, here's my advice to succeed at monoliths this time:

1. **Decouple everything:** HTTP, Persistence, Service and Domain layers should not know anything about each other. Use translation techniques like DTOs to go from one layer to the other.
2. **Think of microservices as modules in your codebase:** apply the same principles of separation of concerns that you used in microservices but now to the same codebase. Define high level interfaces that others can use to access what you implemented in a simple way.
3. **Define boundaries and make people own them:** assign a team for the billing module and other for the invoice module. Make them put their code in different folders and forbid them to touch each other's code. Enforce the boundaries with a CODEOWNERS file and a good CI config.
4. **Enforce good coding practices and patterns:** prevent the codebase from rooting at all costs. Always push for better code and don't let technical debt sink in. Monoliths rot faster than microservices, so they require special care.

I hope this new "coming back to the monolith" trend gives us the chance to learn from our mistakes and perform well the art of building a monolith this time.