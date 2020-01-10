---
title: Repositories as Collections
draft: true
---

The repository pattern is one of the most well established patterns in Domain Driven Design. There's probably not a single project that I have started where I do not use it. 

Of course, like it happens with almost every pattern or tool, you can really use it terribly the first time (or even the second, or the third one). The only way to improve upon that is good literature and seeing other, more appropriate, uses of the pattern/tool. Refining your use of tools and patterns this way is, with almost all certainty, the only way to grow as a developer. Years of experience don't count much if you have been doing the same thing, the same way, over and over again.

So, I want to walk you through my own personal journey with the repository pattern. It may happen that one of the stages that I'm going to describe is the one you find yourself. It might happen that I haven't reached your level yet. Nevertheless, at the end of this article, I explain in detail what is my current approach and why I think is the best one I've seen so far. Feel free to contribute your own. Knowledge is too good a thing to keep ip hidden in your mind.

> NOTE: In honor to today's Start Wars IX worldwide release, I decided to name the levels accordingly. Enjoy!

## Youngling: The Doctrine ORM bare repo

I remember when I moved from Laravel to Symfony, and I had to learn how to use Doctrine ORM. I was unaware of the concept of repository, and its meaning to me was pretty much the Doctrine ORM implementation: a class with some methods that help you to fetch data.

At this level, I usually did something like this in my controller:

```php
class QuotaController extends Controller
{
    public function allQuotas(): Response
    {
        $repo = $this->getDoctrine()->getRepository(Quota::class);
        $array = $repo->findAll();

        return $this->json($array);
    }
}
```

If my needs were a little bit more complex than what the built-in repository methods could handle, then I would add some custom methods to the repository class:

```php

use Doctrine\ORM\EntityRepository;

class QuotaRepository extends EntityRepository
{
    public function getAllExpiredQuotas(): iterable
    {
        // Some query builder logic...
    }   
}
```

The problems with this approach are evident: there's no abstraction. I'm coupling HTTP specific code to a very specific repository implementation. Of course, that didn't seem to be a problem for me at that point.

## Padawan: Eberlei's blog post

With time, I started to research the pattern better, specially because I had problems with the explosion of query methods. I even had the terrible idea of returning instances of the query builder to the controller classes, letting them do filtering and pagination (a horrible idea). 

That was until I read [Benjamin Eberlei's post][1] on the subject of taming the repository methods by using the specification pattern.

I fought to implement specification, but to no avail. Its tremendous complexity was too much to make the pursuit worth. At the end, I just resigned myself to the huge list of repository method names.

## Jedi Knight

After my reading of [*Domain Driven Design*, by Eric Evans][2] (a must-read for any serious developer) and watching some of the excellent [*Rigor Talks* by Carlos Buenosvinos][3], I realized that repositories were not a Doctrine ORM invention, but a domain one. Repositories were meant to be an abstraction over persistence details. The implementation was no concern of the domain layer; the public api was the only important thing.

So here is when I started to treat my Doctrine repositories like an implementation of a domain concern. I would create an interface for that repository and wire it up with the rest of the business logic. I would worry about persistence details later in the development.

```php
interface QuotaRepository
{
    public function ofId(string $id): ?Quota;
    
    public function ofCompany(string $id): iterable;

    public function add(Quota $quota): void;

    public function remove(Quota $quota): void;
}
```

That interface was trivial to implement: just extending the base `EntityRepository` was enough, and adding the methods on top. But I still had all the problems with the explosion of query methods. At least, I had managed to abstract away persistence details from my domain logic completely: I could type the repository interface to any application service and expect it to work.

## Jedi Master

[ThinkToCode][4], a great blog by Jeffrey Verreckt, gave me in [one of it's articles][5] the missing piece about repositories that I needed to understand, and from that I developed an implementation that I consider almost perfect to my needs.

So, a repository is really an abstraction for a collection, that's all. For a long time I saw repositories much like a service, but when I started seeing them as collections, everything changed.

I started to think and came up with some of the ideas that I hold true for collections. For instance, collections should be iterable, sliceable and countable. They are not really collections if they don't have those capabilities.

Also, collections should be filterable, but that filter method should be implemented in an immutable fashion. This means that it does not matter if the implementation is an in-memory or a persistent one: it should not modify the original reference and always return a new one with the applied filter.

I programmed a proof of concept developing a collection using these principles, and implementing it in-memory.

```php
interface Collection extends Countable, IteratorAggregate
{
    public function slice(int $offset, int $size): self;

    public function count(): int;

    public function getIterator(): Iterator;
}

interface OrderCollection extends Collection
{
    public function  
}

```
 

[1]:
[2]: 
[3]:
[4]:
[5]: