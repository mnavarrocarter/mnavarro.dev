---
title: Repositories as Collections
draft: true
---

The repository pattern is one of the most well established patterns in Domain Driven Design. There's probably not a single project that I have started where I do not use it. 

Of course, like it happens with almost every pattern or tool, you can really use it terribly the first time (or even the second, or the third one). The only way to improve upon that is good literature and seeing other, more appropriate, uses of the pattern/tool. Refining your use of tools and patterns this way is, with almost all certainty, the only way to grow as a developer. Years of experience don't count much if you have been doing the same thing, the same way, over and over again.

## Modeling the desired api

I implement and use repositories very differently now than the first time I started. This is probably because of the experience (both good and bad) that I've accumulated over the years. I've also read quite a lot on the topic, and certain I'm not the only one that has experienced issues implementing repositories in my applications.

But one day I decided that I needed to fix this, and find a suitable api for my repositories. So let's say that I'm trying to display a list of books copies available for lending, based on a query string provided by a user.

```php

```