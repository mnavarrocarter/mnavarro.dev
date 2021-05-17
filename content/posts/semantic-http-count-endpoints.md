---
title: Implementing count endpoints using semantic HTTP
subtitle: How to take advantage of the features already available in HTTP to implement count functionality in your apis.
tags: 
    - http
    - rest
    - apis
draft: false
date: 2020-10-15T01:00:00+01:00
---

The HTTP protocol, the REST architectural pattern and API design are amongst my favorite topics in software development. I closely follow the latest RFCs, technologies and standards built over these, and over the years I've learned how not to repeat the mistakes of the past by improving the way I used to to things.

Count functionality implemented in a poor way is one of those mistakes. Back in the day I would have my api resources implement a count endpoint like this: `GET /some-resource/count`. This would return a json along these lines:

```json
{
    "count": 3253
}
```

The problem with this approach is manyfold. I'll point the issues and explain why this is not a good idea, and then I will propose an alternative approach.

## It's Harder to Maintain

If you define count as an endpoint, you have to implement the handler for that endpoint explicitly for every resource. (This unless you are creating your apis with schema definitions and code generation tools). 

In PHP, would look something like this:

```php
<?php

$router->nested('/users', function ($router) {
    $router->get('/', indexUsers());
    $router->get('/count', countUsers());
    $router->get('/:id', showUser())
});

$router->nested('/likes', function ($router) {
    $router->get('/', indexLikes());
    $router->get('/count', countLikes());
    $router->get('/:id', showLike())
});
```

Another downside of this, is that due to the way routing engines work, you need to define the `/count` endpoint before the `/:id`. Otherwise `count` will match as a resource of users, probably giving you a 404. I've seen routing bugs like this more times that I would like to. Junior developers can spend hours on a bug like this trying to figure our why their routes don't match.

So for every time you implement a new resource, you must remember and implement their corresponding count also.

## Tends to duplication

If you are a good api developer, then you are building filtering logic using query params over your collection endpoint. In other words, you are doing `GET /users?status=inactive&role=admin` instead of `GET/users-inactive-and-admin`. The main benefit of this is composability, and also mental sanity. Query params can be composed together to form collections representations with different rules and filters, instead of binding a hard-coded, uncomposable route to yet another handler.

Chances are you want your count endpoints to use that filtering logic too. If you are not a careful developer, you might be temped to just copy and paste the code that handles the query params into the count methods, making it harder to maintain. Kudos to you if you thought of extracting that to a separate method/service, but I would say that while you ara avoiding duplication, you are missing the larger picture: maybe the duplication is an indication that those two things should not be separated in the first place.

## Breaks REST

Even though is perfectly possible to implement count in the aforementioned way, that approach does not follow the REST standard. REST focuses on operations over resources. Resources can be represented inside a collection or as a single unit, but that representation must be consistent. Traditionally, this has been implemented in apis as `GET /resource` for collections and `GET /resource/identifier` for a single resource. `GET /resource/count` gives the impression of a single resource with the identifier `count`. But this "resource" is special: it does not return the same representation: just a number. 

**The truth is that a count is metadata about a collection of resources**, so it should not be implemented at the path that traditionally has been used to define single resources. We have see that this can confuse the routing engine, but also a client of your api.

## A Better Approach

Let's remember our use case. We want to count resources in a collection. Sometimes we would use filters to count them and we want the count to change on those filters. But we don't want to use another endpoint because it's cumbersome and leads to confusion. As we said, count is metadata of a collection so, why not put the count in the collection endpoint? Mmm...will something like this work?

```json
{
    "meta": [
        "count": 13532,
        "page": 13
    ],
    "data": [
        ...
    ]
}
```

This is better, but not ideal. What happens if I just need the count? How do I get rid of the unnecessary json rendering of the representation is that's the case?

Well, turns that we a bit of tweaking and some semantic HTTP we can do better. HTTP has an obscure verb that can help us here, a verb to return just the headers of a request, but not the body: **the `HEAD` verb**.

By HTTP spec, `HEAD` should not have a return body but must have the exact same headers than the normal `GET` request. You would be happy to know that the most popular routing libraries match `HEAD` requests to your `GET` requests automatically for you. This is done in the [Laravel Router](https://stackoverflow.com/questions/22118598/laravel-routes-gethead) for example.

So, what if we move the `meta` object we defined in the json to the response headers? Is not that the purpose of the headers in HTTP, to serve as metadata? So, we can have a response like this:

```http
HTTP/1.1 200 OK
Date: Sun, 10 Oct 2010 23:26:07 GMT
Server: Apache/2.2.8 (Ubuntu) mod_ssl/2.2.8 OpenSSL/0.9.8g
Content-Type: application/json
X-Total-Count: 23432

[
    {
        "id": "some-id",
        "name: "some-name"
    },
    {
        ...
    }
]
```

We moved the array to the top level and move the metadata to the headers. Now, if we want just the count, we can simply do `HEAD /users` and return just the headers, but not build a json body when the request method is `HEAD`. You save a database call and a lot of transformation logic, and you still get your count. And you can use your regular query params to filter data over that endpoint.

## Extra Advice

I like to separate my actual resources from the fact they are a paginatable and countable collection of things. So, I usually split my resource logic with my collection handling logic. 

My collection handling logic just uses a simple interface:

```php
<?php

interface Collection {

    public function count(): int;

    public function slice(int $offset, int $size): Collection;

    public function iterator(): iterable;
}
```

What is under this I don't really care much and long as it gives me a total count, and I can slice it for pagination purposes and filter over it.

Then, I have a single collection handler that, when passed a `Collection` interface, is capable of counting, paginating and rendering the body using the iterator if necessary.

---

Hope you liked this article and that you find it useful.