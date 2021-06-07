---
title: Preventing tenant pollution in multitenant applications
subtitle: Or how to make your multi tenant application tenant unaware
tags: 
    - oop
    - php
    - multitenancy
draft: false
date: 2021-06-06T00:00:00+01:00
---

Last year I built a multitenant system for my employer Spatialest. It was my first time doing a multitenant system, so I researched a lot before doing it. I studied carefully the experience of platforms like Shopify, as their multi tenant requirements were similar to ours. But even after some careful study, I made some mistakes.

One of those mistakes is what I've come to call **tenant pollution**. This means that many services or routines need the tenant as an argument in order to do something. This causes the tenant or the tenant unique identifier to be passed around many layers of the codebase. Basically, the tenant was **everywhere** in the code.

For example, this is a small part of our filesystem interface:

```php
<?php

interface Filesystem
{
    public function put(string $tenantId, string $path, StreamInterface $contents): void;

    public function get(string $tenantId, string $path): StreamInterface;
}
```

The implementation contains a `TenantProvider` that can use the tenant id to retrieve information about the tenant and use that information to determine the folder name where all the tenant files should be stored.

All of our services are pretty much similar. Here is another example of the `EmailFactory`, that creates email messages.

```php
<?php

interface EmailFactory
{
    public function create(string $tenantId, string $messageName, array $data = []): Email;
}
```

The approach is pretty much similar to the filesystem one. We pass the tenant so we can fetch their settings. With the settings, we will created custom branded emails for our tenant with their corporate logos and images.

I have to say that when I was implementing all these services I sort of smelled this. Didn't liked it, but I preferred to the alternative of shared internal service state. And there is nothing I am more against than that. It is terrible OOP.

Many developers would do this. They will remove the tenant and pass it to a setter in the service.

```php
<?php

class ConcreteEmailFactory
{
    public function setTenant(Tenant $tenant): void
    {
        $this->tenant = $tenant;
    }

    public function create(string $messageName, array $data = []): Email
    {
        // Do the action.
    }
}
```

But, once you set the tenant state you could run into all sorts of undesired side effects. PHP does not make this very obvious, due to the fact that when executed in CGI mode all the state is regenerated across requests. But when you are using React PHP or spinning workers in Road Runner, that's when it bites you. If you move to other languages you cannot and must not do this. PHP should not be the exception.

But I sort of had a realization when working in the frontend with React and other frameworks. You see, state in frontend is everywhere. Everything is side-effecty and built around state. Frontend developers live with this reality all the time. It teaches them not to *fear* state, but to tame it and manage it properly. This is the reason why React's `useEffect` hook exists.

I asked myself. Okay, shared state stored in a service is bad but, is there a way in which I could control it, or tame it?

I said, first, let's acknowledge it's existence in an interface:

```php
<?php

interface TenantState
{
    public function initialize(Tenant $tenant): void;
}
```

Now, how can unset that initialized state so I avoid side effects? Like `useState` in React works: I will return a `callable`.

```php
<?php

interface TenantState
{
    public function initialize(Tenant $tenant): callable;
}
```

This is how it would look in the email factory:

```php
<?php

class ConcreteEmailFactory
{
    public function initialize(Tenant $tenant): callable
    {
        $this->tenant = $tenant;
        return function () {
            $this->tenant = null;
        };
    }

    public function create(string $messageName, array $data = []): Email
    {
        // Do the action.
    }
}
```

The secret is this: when executed, the callable will leave the class in it's original state. Now, you can group a bunch of these services into a composite initializer and have a single place in your code where you will initialize all the tenant state, group the callables to unset the state, and then 

```php
<?php

class CompositeTenantState implements TenantState
{
    /** @param TenantState[] $states **/
    private array $states;

    public function __construct(TenantState ...$states)
    {
        $this->states = $states;
    }

    public function initialize(Tenant $tenant): callable
    {
        $unsets = [];

        foreach ($this->states as $state) {
            $unsets[] = $state->initialize($tenant);
        }

        return function () use ($unsets) {
            foreach ($unsets as $unset) {
                $unset();
            } 
        };
    }
}
```

You implement `TenantState` in every service that needs the tenant, and you pass it to this composite implementation. 

This approach is great. If you are using middleware, you can initialize all the tenant state early in the pipeline, and then, when the request has finished, you unset all the state you have set. It is useful also for centralizing initialization of many services at once, so if you need to run the same logic in a console command, you can set up all the services for a tenant and use them freely.

I wish I could have done this since the beginning. Object graphs would be simpler and methods shorter. Well, I guess you never cease to learn.