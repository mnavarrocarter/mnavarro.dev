---
title: Repository Pattern Done Right
subtitle: My long take on how to implement repositories in an abstract, collection-like, immutable way
draft: false
categories: ["Tech"]
tags: ["PHP", "OOP", "ORM", "DDD", "Advanced PHP"]
date: 2020-02-17T20:00:00-03:00
---

The repository pattern is one of the most well established patterns in Domain Driven Design. It's origins can be traced as early as when Object Oriented Programing was born.

Of course, like it happens with almost every pattern or tool, you can really use it terribly the first time (or even the second, or the third one). The only way to improve upon that is good literature and seeing other, more appropriate, uses of the pattern/tool. Refining your use of tools and patterns this way is, with almost all certainty, the only way to grow as a developer. Years of experience don't count much if you have been doing the same thing, the same way, over and over again.

This is why I implement and use repositories very differently now than the first time I started. This is probably because of the experience (both good and bad) that I've accumulated over the years. I've also read quite a lot on the topic, and certainly I'm not the only one that has experienced issues implementing repositories in my applications.

So, with the years, I've come to a definition of repositories, and is this one:

> Repositories are an specific and immutable abstraction over a collection of domain objects.
>
> ~ Matías Navarro Carter

Let me tell you what I mean by that.

## Warning: Active Record Users

Repositories tend to work with ORMs -- even though is not a requirement, it's very common practice. However, not any kind of ORM can be used for working with repositories. I think a word of warning is necessary for users of Active Record ORMs (I'm talking about you, Yii and Laravel users). I've read several blog posts (like [this one][laravel-repo-devto], or [this other one][laravel-repo-medium]) that promise an implementation of repositories the Laravel Way™, which is really not the repository pattern, but a poorly abstracted interface over Eloquent. Don't get me wrong: Active Record ORMs are good on what they do, they just don't fit the requirements for the repository pattern. Don't try to use Active Record ORMs for repositories: they just don't fit the use case. Embrace Active Record: you already made the choice of coupling your data model to your persistence layer. If you won't take my word for it, [take Jeffrey Way's][jeffrey-podcast].

[laravel-repo-devto]: https://dev.to/asperbrothers/laravel-repository-pattern-how-to-use-why-it-matters-1g9d
[laravel-repo-medium]: https://itnext.io/repository-design-pattern-done-right-in-laravel-d177b5fa75d4
[jeffrey-podcast]: https://laravelpodcast.com/episodes/9dafa72e?t=34m3s

## Repositories are Abstractions

Just to continue with the thread, the main reason why Active Record ORMs don't fit the repository pattern is because **repositories are abstractions**, and Active Record Data Models are not. When you create a data model in Laravel, for example, you are not fetching a *pure* data class, but a whole lot of other stuff related to persistence, like your database connections, mutators and all sorts of stuff. All that lives in your data model, and that renders it unusable for the level of abstraction required for the repository pattern.

To be fair with the Eloquent guys, this is true of Doctrine repositories also. If you are using doctrine repositories *as they are*, you are not abstracting anything away. You are coupled to Doctrine, which is in turn coupled to a relational database engine. That leaves you in the same place as using Eloquent (a bit better though, because your data model is a *pure* data class).

In the Symfony world, it's common to see something like this:

```php
<?php

class SomeController
{
    public function someMethod(Request $request): Response
    {
        // This repository is the doctrine's library one
        $repo = $this->getRepository(User::class);
        $users = $repo->findAll();
        return $this->json($users);
    }
}
```

If you do this, stop. You are not using a **proper** abstraction here. It's true: the Doctrine repository is an abstraction over the `EntityManager`, `QueryBuilder`, `Connection` and a bunch of other stuff: but is a doctrine-specific abstraction. You need a **Domain-specific abstraction**. One abstraction that is only yours, your own contract.

So what we should do then? We just define an interface:

```php
<?php

class User
{
    // This is your data class
}

interface UserRepository
{
    /**
     * @return iterable|User[]
     */
    public function all(): iterable;

    public function add(User $user): void;

    public function remove(User $user): void;

    public function ofId(string $userId): ?User; 
}
```

This is a proper abstraction. Your `User` class is a class that just contains data. Your `UserRepository` interface is your contract. You can use the Doctrine repository behind it, but it won't matter this time, because you will type hint the interface to all other classes using it. This way you effectively decouple yourself of any persistence library/engine and get an abstraction you can use all around your codebase.

## Repositories are Specific

Note how the `UserRepository` we defined is **model specific**. A lot of people like to save work by creating a generic repository, that becomes no more than a query abstraction over the persistence library used. Just don't do this:

```php
<?php

interface Repository
{
    /**
     * @return iterable|object[]
     */
    public function all(string $repositoryClass): iterable;
}

```

Remember one of the principles of DDD: clear language intent. One repository interface for each model conveys more meaning to that specific repository/model than a generic one. For example: only users can be filtered by email, not buildings.

Besides with one generic repository for everything, you won't be able to type your concrete model classes to the return or argument types. It's the longer route, but is definitely the most convenient and flexible.

## Repositories are Collections

I would say that the "Aha!" moment in repositories for me is when I realized that they are just an abstraction over a collection of objects. This blew my mind and gave me a new challenge; the challenge of implement repositories as if they were an in-memory collection.

For starters, I dumped all methods like `all()`, `allActiveUsers()` or `allActiveUsersOfThisMonth()`. If you have read the two famous posts about taming repositories, first the one of [Anne at Easybib][anne-post] and then the one of [Benjamin Eberlei in response][ben-response], you should know that methods like that in a repository can really grow wild. Also, you don't need all the complexity of the specification pattern: we can do better and simpler than that.

[anne-post]: http://drafts.easybib.com/post/44139111915/taiming-repository-classes-in-doctrine-with-the
[ben-response]: https://beberlei.de/2013/03/04/doctrine_repositories.html

Collections apis have many distinctive features: the possibility of slice them, filter them, and add or remove new items to them as well as getting individual items. But we don't want a general collection api, remember? We want to implement a specific api for every model, so it conveys meaning. 

So, our `UserRepository` interface could look this way:

```php
<?php

interface UserRepository extends Countable, IteratorAggregate
{
    public function add(User $user): void;

    public function remove(User $user): void;

    public function ofId(string $userId): ?User;

    public function ofEmail(string $email): ?User;

    public function withActiveStatus(): self;

    public function registeredAfter(DateTimeInterface $date): self;

    public function registeredBefore(DateTimeInterface $date): self;

    public function getIterator(): Iterator;

    public function slice(int $start, int $size = 20): self;

    public function count(): int;
}
```

Pay special attention to the last three methods. These are the only methods that could potentially be in a `Repository` base interface, because all of them will be sliceable, countable and iterable.

```php
<?php

interface Repository extends IteratorAggregate, Countable
{
    public function getIterator(): Iterator;

    public function slice(int $start, int $size = 20): self;

    public function count(): int;
}
```

So by doing this, all of your repositories will be sliceable (think pagination there), iterable and countable. The idea is that you apply the filtering methods (all the methods that return `self`) and then iterate to execute the internal query ¡just like an in-memory collection! In fact, you wouldn't note the difference at all if an implementation is switched to another one.

This is good OOP. All the persistence details are completely hidden from us, the api is composable and fits our needs for a repository. It looks neat and using it is really simple and easy to understand:

```php
<?php

class SomeService
{
    public function __construct(UserRepository $users)
    {
        $this->users = $users;
    }

    public function someMethod()
    {
        $users = $this->users
            ->withActiveStatus()
            ->registeredBefore(new DateTime('now'))
            ->registeredAfter(new DateTime('-30days'));

        $count = $users->count();

        return $users;
    }
}
```

But here's the question: how do we go about implementing an api like this? If you are a good observer, you might have realized that the filters return an instance of themselves, modifying the internal state of the repository. So in a next query, we will have the filters of the previous query applied, right? 

## Repositories are Immutable

Well, that could be right, if we really are modifying the internal state. But in reality, we are cloning the reference of the repository, so we never touch the original one. This is an implementation detail, but a very important one. If we change, let's say, the state of the repository reference that lives inside our DI Container, then we are done: we cannot use that reference again. So the idea is to make it **immutable**.

Let me show you the final api, implemented in Doctrine ORM. I'm going to write some comments and docblocks in the code explaining some things.

```php
<?php
declare(strict_types=1);

namespace RepositoryExample\Common;

use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\QueryBuilder;
use Doctrine\ORM\Tools\Pagination\Paginator;
use Iterator;

/**
 * Class DoctrineORMRepository
 * 
 * This is a custom abstract Doctrine ORM repository. It is meant to be extended by
 * every Doctrine ORM repository existing in your project.
 * 
 * The main features and differences with the EntityRepository provided by Doctrine is
 * that this one implements our repository contract in an immutable way.
 * 
 */
abstract class DoctrineORMRepository implements Repository
{
    /**
     * This is Doctrine's Entity Manager. It's fine to expose it to the child class.
     * 
     * @var EntityManagerInterface
     */
    protected $manager;
    /**
     * We don't want to expose the query builder to child classes.
     * This is so we are sure the original reference is not modified.
     * 
     * We control the query builder state by providing clones with the `query`
     * method and by cloning it with the `filter` method.
     *
     * @var QueryBuilder
     */
    private $queryBuilder;

    /**
     * DoctrineORMRepository constructor.
     * @param EntityManagerInterface $manager
     * @param string $entityClass
     * @param string $alias
     */
    public function __construct(EntityManagerInterface $manager, string $entityClass, string $alias)
    {
        $this->manager = $manager;
        $this->queryBuilder = $this->manager->createQueryBuilder()
            ->select($alias)
            ->from($entityClass, $alias);
    }

    /**
     * @inheritDoc
     */
    public function getIterator(): Iterator
    {
        yield from new Paginator($this->queryBuilder->getQuery());
    }

    /**
     * @inheritDoc
     */
    public function slice(int $start, int $size = 20): Repository
    {
        return $this->filter(static function (QueryBuilder $qb) use ($start, $size) {
            $qb->setFirstResult($start)->setMaxResults($size);
        });
    }

    /**
     * @inheritDoc
     */
    public function count(): int
    {
        $paginator = new Paginator($this->queryBuilder->getQuery());
        return $paginator->count();
    }

    /**
     * Filters the repository using the query builder
     *
     * It clones it and returns a new instance with the modified
     * query builder, so the original reference is preserved.
     *
     * @param callable $filter
     * @return $this
     */
    protected function filter(callable $filter): self
    {
        $cloned = clone $this;
        $filter($cloned->queryBuilder);
        return $cloned;
    }

    /**
     * Returns a cloned instance of the query builder
     *
     * Use this to perform single result queries.
     *
     * @return QueryBuilder
     */
    protected function query(): QueryBuilder
    {
        return clone $this->queryBuilder;
    }

    /**
     * We allow cloning only from this scope.
     * Also, we clone the query builder always.
     */
    protected function __clone()
    {
        $this->queryBuilder = clone $this->queryBuilder;
    }
}

```

That was the abstract repository. Note how we don't expose the `QueryBuilder`. This is because it's dangerous: an inexperienced developer could apply filters to it and mutate the original reference, causing a massive bug. Instad, we provide two convenience methods for child classes, `filter` and `query`. The first one takes a callable which in turn takes a cloned instance of the `QueryBuilder` as an argument. The second one just returns a cloned `QueryBuilder` so the child class can query anything.

Then, we use that api in our `UserRepository` and implement the remaining methods.

```php
<?php
declare(strict_types=1);

namespace RepositoryExample\User;

use DateTime;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\NonUniqueResultException;
use Doctrine\ORM\NoResultException;
use Doctrine\ORM\QueryBuilder;
use DomainException;
use RepositoryExample\Common\DoctrineORMRepository;

/**
 * Class DoctrineORMUserRepository
 * @package RepositoryExample\User
 */
final class DoctrineORMUserRepository extends DoctrineORMRepository implements UserRepository
{
    protected const ENTITY_CLASS = User::class;
    protected const ALIAS = 'user';

    /**
     * DoctrineORMUserRepository constructor.
     * @param EntityManagerInterface $manager
     */
    public function __construct(EntityManagerInterface $manager)
    {
        parent::__construct($manager, self::ENTITY_CLASS, self::ALIAS);
    }

    public function add(User $user): void
    {
        $this->manager->persist($user);
    }

    public function remove(User $user): void
    {
        $this->manager->remove($user);
    }

    public function ofId(string $id): ?User
    {
        $object = $this->manager->find(self::ENTITY_CLASS, $id);
        if ($object instanceof User) {
            return $object;
        }
        return null;
    }

    /**
     * @param string $email
     * @return User|null
     */
    public function ofEmail(string $email): ?User
    {
        try {
            $object = $this->query()
                ->where('user.email = :email')
                ->setParameter('email', $email)
                ->getQuery()->getSingleResult();
        } catch (NoResultException $e) {
            return null;
        } catch (NonUniqueResultException $e) {
            throw new DomainException('More than one result found');
        }
        return $object;
    }

    public function withActiveStatus(): UserRepository
    {
        return $this->filter(static function (QueryBuilder $qb) {
            $qb->where('user.active = true');
        });
    }

    public function registeredBefore(DateTime $time): UserRepository
    {
        return $this->filter(static function (QueryBuilder $qb) use ($time) {
            $qb->where('user.registeredAt < :before')
                ->setParameter(':before', $time, Types::DATETIME_MUTABLE);
        });
    }

    public function registeredAfter(DateTime $time): UserRepository
    {
        return $this->filter(static function (QueryBuilder $qb) use ($time) {
            $qb->where('user.registeredAt > :after')
                ->setParameter(':after', $time, Types::DATETIME_MUTABLE);
        });
    }
}
```

The result is really nice to work with. I've taken this approach is several projects so far and it feels great. The method names convey meaning and work well. Creating different implementations like a Doctrine Mongo ODM, Filesystem or In-Memory it's trivial. Implementors just need to take into account the immutability aspect of it, but that's all really.

I really hope you like this approach as much as I do and start using it in your projects.