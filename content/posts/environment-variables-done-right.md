---
title: Environment Variables Done Right
subtitle: Some advice and guidelines to keep your environment variables under control
tags: 
    - env
    - php
    - docker
    - development
draft: true
date: 2020-07-02T20:00:00+01:00
---

One of the things that I don't like about Laravel is their abusive use of environment variables. I think it sets a bad precedent for when developers need to come up with their own environment variables in their applications. 

I have seen environment variables in an application that should have never been environment variables. And other things that should have been but have not made it to the list. 

So, I thought I'll write this piece to rant a bit about this.

## Know what should be an environment variable

Environment variables should only be configuration values that change between deployments. Nothing else. For instance, Laravel has it's famous `APP_NAME` environment variable that is completely useless. If your app name is `MonkeyMarket` is probably going to be the same in production and staging deploys. No need to make this an environment variable at all. It is not a value related to the environment, but to the application. This is best handled in code.

`APP_URL` is probably another environment variable that should not exist, since the app url should be derived from the `Host` http header or any of the `X-Forwarded` or `Forwarded` headers (if you are behind a proxy). If you don't do that, then you risk to inconsistencies between the actual app url and the value of the `APP_URL` variable. Having said that, there are probably some scenarios in which it might make sense, specially if you want to avoid proxy forgery attacks.

## Use URIs to specify connection parameters

Another thing that Laravel does with their environment variables is to multiply their number without need. For example, in order to specify a database connection, you must set a total of 6 environment variables: `DB_CONNECTION`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` and `DB_PASSWORD`. It's a similar thing if you want to configure mailing or storage.

In order to simplify all these possible options you can make use of URIS. As defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986) they provide a simple and extensible way of defining a resource. In our case, this resource would be a connection to a third party service.

For instance, instead of all those variables that Laravel defines for a database connection, we could use a single uri string. This even allows us to pass extra configuration in the form of query parameters.

```env
mysql://user:pass@host:345/db_name?collation=utf8&ssl=true
```

What if it gets tricky, like a database connection behind ssh? You still can use a single string and keep complexity of environment variables to a minimum.

```env
mysql+ssh://user:pass@host:345/db_name?collation=utf8&sshHost=192.168.1.123&sshUser=root#/path/to/ssh/key
```

This can work for virtually anything, like mailing, caching, storage, and sessions.

```
DATABASE_URI=mysql://user:pass@host:345/db_name
MAILING_URI=smtp://user:pass@host:port?from=app@example.com&ssl=true
CACHING_URI=local:///tmp/cache
STORAGE_URI=s3://accesskey:secret@s3.amazonaws.com/publican?region=us-east-1
SESSION_URI=redis://user:pass@host:port/path/of/keys
```

You can easily parse all these values using PHP's `parse_url` built-in function and get some defaults out of them.

## Everything should have a default

Is my personal belief that a good application should work out of the box with really dummy defaults. For instance, if your application needs a SQL database, maybe it should work with `sqlite` by default, either in the filesystem or in memory. If it needs to store session data, it should probably default to the filesystem instead of `redis`. If it needs to send emails, it should do it in memory or write them in the filesystem unless a real driver is provided.

No environment variable should be strictly required to run the application, and the defaults should probably be development ones, so every developer in the project can jump quickly boot the environment.

## Derive as much non-secret values as you can

Something I've seen a lot in many projects is environment variables with URLS to third party services that the app depends on.

You might be inclined to store this in an environment variable of the type `SERVICE_X_URL` too, since the values can change according to the environment. But another lesson to learn here is that in most cases you can derive these values from another environment variable. You could have an `APP_ENV` variable with some predefined possible values (prod, stage, local, test) and use that to derive other values.

The better approach in this case is that the urls should be stored in code (constants are useful here) and you should derive the right url according to the current environment stored in the `APP_ENV` variable.

So, if `APP_ENV` equals to the string `prod`, then you know you should use the production url for that service. In all other cases, you use the staging url. This is very convenient since you don't have to maintain a `SERVICE_X_URL` environment variable. You could even create mocks of the service and run those when the environment is `local` or `test`.

If the service needs authentication, like a Bearer Token, you should create an environment variable for that, as the token can be different for every deployment, but unlike the url, it is not a secret value, so hardcoding it would be a terrible security best practice violation.

Also, I should not say that as a good integration practice all that information
should be stored in an class implementation of that service.

> NOTE: You should not do this if these are services that could be deployed to different urls (like a pdf converter microservice or some other tool) and therefore could change often. This approach is only useful for services that have a staging url and a production url that usually does not change.

## Use other alternatives

Some people like to use an `APP_DEBUG` environment variable to determine if the application should be in debug mode or not. I personally don't like this. Debugging is something you need to turn on and off on demand. Having it in an environment variable means an application restart is required to pick up the changes (in a containerized environment), which could affect your debugging.

Here the use of feature flags shines. If you use a service discovery tool like Consul, you could store these in their key value store and retrieve them at booting time and use them to configure your services. Redis is another option here.

So, when you need to debug an issue you could enable that feature and then turn it off when you don't need it anymore.

---

Hope these tips help you reason about what environment variables you define in your application and to keep them under control.