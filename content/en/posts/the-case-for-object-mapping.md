---
title: "The case for Object Mapping"
subtitle: A series of reasons why working with objects mapped from the persistence layer is always better than using raw PHP arrays (hash maps)
draft: false
date: 2020-04-28T20:00:00-00:00
categories: ["Tech"]
tags: ["ORM", "Data Structures", "Software Architecture", "PHP", "Design", "OOP"]
---

## Introduction: A Tale of Simplicity VS Complexity

> NOTE: Every time the word **array** is used in this article I'm referring to the PHP definition of this term. You can also consider that term equivalent, for the purposes of this article only, to use instances of `stdClass` or instances of classes that contain dynamic public properties, like Active Record Models. This is because the deficiencies pointed with arrays apply to those constructs as well.

The selling point for PHP in its early days was simplicity. It promised an escape from the complex ways of Java, .NET and others, that felt too cumbersome for people that wanted to do simple tiny scripts. The promise was that you didn't need to think about data structures, memory allocation, objects, inheritance, third party libraries and so on and so forth if all you wanted was to dynamically render a bit of content on a page.

The problem is that PHP grew in popularity. People started to ask more and more functionality to be able to do more advanced things, and somehow the language grew in a very un-organic way; but that's another story. The point I'm trying to make is that PHP ceased to be used for simple scripts. Complex enterprise-scale applications are being built in PHP nowadays. And suddenly, we realized that this language that was so friendly for small and simple stuff, is not that friendly for big and *enterprisy* things: at least not used in the traditional ways.

This is the reason why the PHP Internals team has been investing a lot of development time in features that would make the language more reliable, like runtime type checking and improved object oriented support. The fact that the language was being heavily used for large-scale applications led to the realization that we needed more appropriate features to support that use. 

This is not a PHP-only realization. The story of Javascript is quite similar. Javascript, as a language, was conceived to make your mouse drop color sparks on movement, or your home banner to drop snow in december. But since its port to the backend by the Node JS runtime, Javascript developers used it to build complex stuff. They realized too that the language was also very unreliable for large-scale business-process-style projects; hence Typescript.

This new push for types and oop features in languages whose initial premise of existence was to get rid of all that **unnecessary complexity** should not be left unnoticed. We have valuable lessons to learn here.

Maybe the lesson is that choosing the simpler solution to a problem only gets you that far. When the problem grows in complexity, the simple approach cannot really cope and, in a glorious paradox, mutates into a complexity monster itself. And maybe the other lesson that we can learn is that costs more time and effort to move to a complex approach from a simpler one, than the other way around.

But you are right. This, at the end of the day, is mere narrative. So I want to tackle this issue with a practical, very common case. The case of object mapping.

## Arrays VS Objects

There are mainly two approaches when working with databases in PHP nowadays. You can either design DAO classes that will contain queries that will fetch you the data that you need in arrays; or you can build your persistence layer on top of an ORM and map those database queries results into well defined classes/objects.

The simpler, faster, more straightforward route is the first one, by far. Here is a comparison in implementation with code. Let's go with the DAO/array approach:

```php
<?php

class UserDAO
{
    private PDO $pdo;
    public function __construct(PDO $pdo)
    {
        $this->pdo = $pdo;
    }

    public function getUserById(string $id): array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM users WHERE id = :id')
        if ($stmt->execute(['id' => $id]) !== true) {
            throw new QueryError();
        }
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}

$pdo = new PDO(/** Connection details here **/);
$dao = new UserDAO($pdo);
$user = $dao->getUserById('some-id');
```

Now, the object mapping approach (Using Doctrine ORM):

```php
<?php

// First, you need to create your entity class with annotations

/**
 * @Entity
 */
class User
{
    /**
     * @Id
     * @Column(type="integer")
     * @GeneratedValue
     */
    private int $id;
    /**
     * @Column(type="string")
     */
    private string $username;
    /**
     * @Column(type="string")
     */
    private string $password;
    /**
     * @Column(type="string")
     */
    private string $email;
    /**
     * @Column(type="datetime")
     */
    private DateTimeInterface $registeredAt;
    
    public function __construct(
        string $username,
        string $password,
        string $email
    ) {
        $this->username = $username;
        $this->password = $password;
        $this->email = $email;
        $this->registeredAt = new DateTime('now');
    }

    // All the getters here, which use more space
}

// Then you need to bootstrap your entity manager
$paths = ["/path/to/entity-files"];
$isDevMode = false;
$dbParams = ['uri' => 'mysql://user:pass@host:port/database'];

$config = Setup::createAnnotationMetadataConfiguration($paths, $isDevMode);
$entityManager = EntityManager::create($dbParams, $config);

// We can then query our objects
$user = $entityManager->find(User::class, 'some-id');
```

Even though the ORM example is not significantly longer in lines, it is more complex for all the jargon and the tooling it introduces. There is a cost to learn how to use an ORM versus how to make SQL queries (supposing the developer already knows how to do the latter).

Now, considering that an ORM **does not have** a significant cost in implementation lines but **it does have** one in learning/training for its use, and **supposing** that that usage brings benefits in the long run, then the million dollar question is: **is that cost worth those benefits?** That's all, really.

In order to answer that question we need to come to see those supposed benefits. The only way to do that is comparing it to the other approach in the context of the daily practice of working in a codebase. I like to draw this comparison by pointing to the deficiencies of the array + DAO approach in short statements, and how the object-mapping approach is different, and better.

## Arrays are not reliable structures, objects derived from classes are

This is THE problem with arrays in PHP: they are very unreliable data structures by design. In the DAO approach, for example, that array returned from the user data can contain anything (who knows what), can be read by anyone with access to the reference, and modified too, without any kind of constraints.

```php

$user['id'] = 1;
$user['username'] = 'Tom';
$user['password'] = 'my-hashed-password';

// You get the idea...
```

This create a host of problems. There are simply so many things can go wrong using them:

1. What if the hashed password of a user gets dumped in a report by accident?
2. What if suddenly `username` is no longer a string but null? How do I know that?
3. What if someone deleted a key that other code depends on because he/she was trying to do something else, like hiding the password, for example?
4. What if I misspelled a key name in a critical production operation?
5. What if I leave the array in a inconsistent state that could affect future computations, like `['isAccountActive' => true, 'deactivationDate' => '05/24/1988']`?

I could go on forever...

## Arrays lead to over-tested code, objects derived from classes require less testing

You could argue that these problems should be solved by testing the system and its routines, and you are absolutely right. This, however, assumes that the developer does test the codebase, which is not always true in my own observations of reality. Nonetheless, being generous, I can concede that.

The main problem here is over-testing. Since your language has features to automatically prevent all the kind of undesirable state mutations that I pointed out, but you are not using them, you end up writing more tests than you should, because now you have to check for invalid state mutations in every routine. This leads, instead of unit testing or spec testing, to case-per-case testing, which is a very expensive way to test. It is expensive because it is really hard to set up, and also because it is very easy to break those tests.

**If you don't want to have problems working with arrays, you have to test your system extensively, adding big costs to the development effort.**

Or, you could use defined classes with protected state, and allow to read only what is necessary, specifying return types and only allowing valid state mutations by providing a good api to client classes. Did I mention you can write comments in its methods too, as means of documentation?

## Arrays are not new-developers friendly, objects derived from classes are

Even when you can get away with testing your codebase extensively to use arrays (which I highly doubt), another problem is that, if I'm not the main developer of the application or I am not familiar with the system in any way, I'm going to have a really hard time working with those arrays if I ever need to fix something. I'll spend hours dumping and debugging what an array exactly contains at any given point in the code, instead of actually solving a problem. I might even try to do that again and again with different inputs. All that is time consuming, and the hourly rate of a developer is not quite cheap to be honest.

How much easier would be for me to jump in to the development effort aided by a good designed class and my favorite IDE's autocomplete and go-to features? Oh, I see that the method `getDeactivationDate` can return an instance of DateTime or null. I can work with that!

**In the long run, using objects reduces development costs by allowing other developers reasoning about the codebase faster.**

You could make the point, however, that this is easily solvable by documenting the structure of arrays in some form of specification. Again, that does not make them not changeable and suddenly trustworthy, but at least is a start. But, can you see the irony? You **need** a spec, and that is exactly what a class is: is an specification, a structure, a contract, a blueprint. The only difference is that is not optional, it is enforced by the language. And better yet, does not live in an obscure word document stored somewhere else, but in your codebase. I don't know about you, but that makes a pretty good spec for me.

I guarantee you: the time that could be spent writing that documentation specification is more than writing the class itself. Why don't make the class the spec then?

## Arrays are anemic, objects derived from classes are rich

Arrays are bags of data with no more meaning that the one you remember from when you were working on the code for the last time. But the things we are doing with our software are full of meaning: we are storing users, login them in, adding or removing permissions. We are managing reservations, scheduling meetings, sending emails, transferring cargo, selling goods, you name it! Surely we are missing something when we try to do that moving around bags of uncertain data.

Having a `User` class with a `login` method sounds pretty straightforward to me. So it does a `Cargo` class with a `transfer` method, or a `Order` class with a `pay` one. I can easily figure out what is going on there. This is what is so cool about objects: state and behavior live together in one place, because in our stateful world, they should!

However, arrays cannot contain any behavior associated with them. So if you want to repeat a routine over a similar structure of data, you have to rewrite that routine somewhere else, which in turn leads to bloated client code. This is the difference between an anemic data model (one that contains just plain data) and a rich one (one that has the data, but also is full of behavior). The latter serves client code better by means of [Telling-Not-Asking][fowler-tda].

To be fair, you can always create a function to perform a common task over an array. But again, that function needs to operate over an array with a very special structure, not any array. And we have seen how easy is to break them. Why separate then that apparent natural association between the data and the actions that can occur over that data?

**But, in summary, using objects helps to encapsulate logic that otherwise would be repetitive, and would lead to bloated client code.**

## Arrays cannot benefit of IDE tooling, objects can

Arrays don't offer autocompletion when working with them, likes objects do. I've sort of mentioned this in the past, but not as explicitly. Autocompletion is a powerful IDE feature that aids the developer and saves him/her from wasting time in silly mistakes. 

Also, arrays are hard to refactor. If you rename a key, you have to track all the uses of that key in your code and change it to the new one. Working with objects and with an appropriate IDE you can refactor a method name in an instant. 

**So again, using objects aids development by means of saving time and improving naming conventions when necessary.**

## Arrays and DAOs do not scale as well as Objects and Repositories do

Queries in DAOS can really grow wild and complex. It's impossible not to have a combinatorial explosion of method names without using some sort of query builder. Also, is even hard to switch between different SQL implementations, like Sqlite, MySQL, Postgres or even Oracle. This increases maintenance time when dealing with changes of schema or implementing new methods.

ORMs abstract away all these details and create some sort of a protection layer between vendors by choosing a subset of their functionality. This is how, at the end of the day, abstraction works: it has the benefits of being consistent, but with a limited subset of functionality. They have excellent query building capabilities already backed into their engines, so we don't have to reinvent the wheel.

This makes ORM scale better in terms of maintainability. Abstracting away all those details helps us focus on writing code rather than worrying about queries. Here the maxim applies more than in any other place: the simpler solution grows complex when the problem grows too. The complex solution costs more up front, but scales better when the problem gets complicated.

## Conclusion

These are probably the main reasons why I think working with objects derived of well designed classes is always going to be better than working with other unreliable data structures. Again, costs more up front (and not so much if you have appropriate tooling like PHP Storm), but the benefits on the long run are huge.

And if these reasons don't convince you, maybe just like a look at the recent trend. Languages historically known to be simpler and flexible adopting more complex and stricter features. That's got to say something, isn't it?

[fowler-tda]: https://martinfowler.com/bliki/TellDontAsk.html