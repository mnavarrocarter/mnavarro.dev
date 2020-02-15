---
title: "On Structuring an Express App"
draft: true
---

[Express js][1] is cool and sexy. It is so minimal and flexible that it was this framework my main inspiration for developing [Espresso][2]. I like it's middleware-centric approach to everything, and I think is that what makes it so powerful.

I've had a good deal of experience developing applications in Node, learning to avoid some pitfalls and common mistakes in the process. One of the things I did at the beginning, and that I've seen others doing, is not to force myself to appropriately modularize the application. Node with Express leaves a lot of decisions to the developer. If you are not careful enough, you can end up by requiring tons of modules on a single one, and mixing domain with http logic.

So what I provide here is a series of guidelines that will help you, hopefully, to better modularize Express apps so your codebase does not turn into a nightmare.

## 1. Separate Domain of HTTP Logic

## 2. Design your modules well

## 3. Decouple your modules using an EventEmitter

## 4. Use decorators a la JS

## 5. Use feature flags

## 6. Use an appropriate logger

[1]: https://expressjs.com/
[2]: https://github.com/espresso-php/http