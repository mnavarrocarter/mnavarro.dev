---
title: Getting Continuous Integration right
subtitle: Because "Continuous Integration" is more about "Continuous" than "Integration"
draft: false
date: 2020-02-26T16:30:00-03:00
categories: ["Tech"]
tags: ["Good Practices", "CI", "CD", "Git", "Gitops"]
---

I've participated in a good number of projects in my short life as a developer. Luckily, when I started in this business, `git` was a thing already and was one of the first tools I learned to use. I often wonder how anyone was able to build software in the past without it.

The best value that `git` brought to software development was not so much related to keeping a versioning history of a codebase (which is already pretty big value!). I think the bigger value is definitely related to code integration. Git, along with other tools, made the complex art of code integration way easier.

In the past, you had to copy the code you wrote, with tests and everything, back to the master copy and hope you didn't break anything. Automated tests were run locally, and a test environment was always in place ready for that. That sounds simple enough if you are working alone. But imagine integrating changes of many development teams across the same codebase like that. What a nightmare!

Nowadays with `git` you can push your changes to a remote repository and automated tools perform checks and run tests on that integrated piece of code, with the amazing possibility of writing reviews and provide feedbacks. What an amazing time to be alive!

{{< figure src="https://media.giphy.com/media/zCv1NuGumldXa/giphy.gif" title="Unlimited power!" >}}

Truth is that code Integration exists since software development started to be a thing. Everyone needs to integrate code to a master codebase. The million dollar question is really, is your process for integrating code smooth enough that allows you to integrate code *continuously*? Could you integrate code to the master branch six or seven times per day, from different developers, and be confident that works? Because that's the requirement today.

Fagner Brack, one of my personal favorite tech writers, [wrote a few years ago][brack-merge-post] about how six months of his work were turned into vaporware because of a big merge that had so many conflicts that was impossible to solve and therefore, integrate to the main codebase.

I think stories like this happen all the time. 

You are working on a big feature, you change classes, move files, and create new resources over a long period of time. Then, in the meantime, other developers are changing the codebase, modifying the files you renamed or moved (brace yourself!) or even changing method names. No matter what tool you use: integrating that is going to be a nightmare.

So, I was thinking would be nice to share some of the ideas and techniques that I've adopted in my experience with integrating code continuously.

## 1. Teach your team how to make modular Software

Modularity in software development is a must. Period. This is not some pharisaical or dogmatical way of thinking, but a very practical one. We don't even do it for the sake of reusability, as some people might think. Truth is, modularity is for pluggability. A module is a piece of a larger puzzle. At any given point in time I may change that piece for other that fits better, but without even touching the rest of the pieces.

This requires that the piece I want to switch is developed in such a way that knows the least possible about the other pieces, and viceversa. My `User` class must know nothing of the `Request` or the `DbConnection` classes. They are totally unrelated pieces. If this does not happen, we'll discover that changing that functionality is going to be a pretty expensive and long task.

Of course, this is not how most software is developed today. Specially in these days where the "Develop quickly; worry never; fix when broken" paradigm seems to be gaining some foot. Most software I've seen has modules that know too much about others and there are not clear boundaries between them most of the time.

The only way to solve this is by teaching and learning. You must be willing to invest time to teach your team not only why developing like this is important, but the techniques and the programming language features that will help them develop this way. Teach them to see a problem and break it down in independent pieces, and then teach them to code to interfaces, dependency injection, composition, design patterns and unit testing. It takes time, but it pays off tremendously.

## 2. Make developers own their modules

Once your team has started to develop in modules, then they must own them. If I created the "HTTP Authentication Module" of a larger application, then I must own that code. I must own it in the sense that I am the only one that can authorize changes to its internals or, more importantly, to it's public api. My mission is to keep that module well documented and stable at all times. When a change is needed, the context is discussed with the rest of the team, but I make the final call. I have full control over it. It's my module.

Of course this is a team effort. I can teach other developer how the module is developed and then he/she can become the maintainer. I'm in no way advocating for solo development or not having the big picture here. My main concern is the changing of code.

This can be easily enforced by using a feature most code management tools like Github or Gitlab have: the possibility to define a `CODEOWNERS` file. It's basically a plain text map of directories to usernames. It defines the users allowed to authorize pull requests that affect code belonging to the specified directory.

This ensures conflicts are reduced to a minimum, because no one is touching other developer's code. This, in turn, makes integration easier and faster. Bonus point: it really forces collaboration and communication between the maintainers of different modules.

## 3. Use a simple and effective git flow

Establishing a clear git flow and explain it to your team is a must. They must know what to do to integrate what they are developing quickly and seamlessly. I've seen organizations over-complicate their git flow adding branches for bugfixes, and for features and for different environments or versions. Remember a very important git rule (coined by myself): every public branch implies a maintenance cost. Someone has to merge it somewhere, or cherry-pick it from somewhere else.

You are using a version control system: you can live with just one public branch. Creating branches for everything sounds like coming back to our old ways of tracking file changes: copying folders named like `project-dev`, `project-final`, `project-prod`, `project-prod-final`, `project-i-swear-this-is-final` and so on.

For my personal taste, what I do is this: `master` is my only public branch. This branch is blocked for pushes, so the only way of integrating code is via pull-request. The rest of the branches are private and therefore disposable. The way work is done is by getting branches from master, developing locally and pushing to the code management system, creating a pull request. On that PR, tests are run and styles and best practices are enforced and personal feedback is provided. If before approval something else gets merged to master, the developer must rebase origin/master locally and force push the result.

This is an extremely simple approach that advocates for a constant flow of commits. Integrating early and frequently is always the best approach, even when building long time features.

## 4. Use feature flags for unfinished, long-time features

Let's say there is a team in charge of revamping the whole UI of our application. Such a project is estimated to be completed in 8 months. In the meantime, there is another team constantly adding new features and views to the application, and fixing bugs.

The worst idea ever would be, in this scenario, that the team tasked with building the new UI creates a separate branch for all their work and develops only there, and merges to master 8 months later only when everything is ready. Why? That merge will face lots of conflicts and will miss the new features developed by the other team. They need to constantly merge new code to the master branch, so they can benefit from the new features and bugfixes that other teams are implementing. This will avoid a *Major Merging Mess* (MMM).

You say "But, it's a UI change! How can they merge it before is finished!? It would look incomplete!". Enter feature flags.

Feature flags are any kind of thing that indicates to your application that it will run under a different feature configuration. Try not to confuse these with environment variables: feature flags don't have anything to do with environments, but with features. Hence the name. If I see you defining features in environment variables, I will find you, and I will kill you (not really!).

Maybe your web app runs in the CLI, kinda *a la node js*. Well, a good feature flag could be adding a command line argument to your `server.js` script. For the use case that we are considering, maybe something like `node server.js --use-new-ui` will suffice. This will, theoretically, load the app but with the new UI, which lives in a folder different to the old one. Developers of the new UI can use this setup, while others can keep using the old one.

But this approach is sub-optimal, because it needs a restart of the application for turning a feature on and off, because of it's coupling with the way the application is executed. A better approach would be to use a centralized storage (redis shines here), and make available and endpoint to turn flags on an off without requiring a restart of the whole application. You can wrap this on a simple `FeatureService` with one simple public method `isTurnedOn(string $featureName): bool`. This is the approach that I prefer.

## Conclusion

I hope this advice leads you in the right way regarding *Continuous* Integration. Never in the history of software development have we had so many and effective tooling/ideas to help us in this process. It's time to make the most of them!

[brack-merge-post]: https://hackernoon.com/continuous-integration-a-merge-story-16d8c81b4077