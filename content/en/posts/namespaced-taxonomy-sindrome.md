---
title: Namespaced Taxonomy Syndrome
subtitle: Correcting bad habits and wrong assumptions in the use of PHP Namespaces
categories: ["Tech"]
tags: ["PHP", "OOP", "Namespaces", "Laravel"] 
draft: false
date: 2020-07-20T20:00:00+01:00
---

## The Discovery of a Syndrome

The past week I had some really nice holidays, but my wife still had to work. That's nice sometimes because it means staying at home with loads of time to do one of my favorite things: getting myself into learning and coding (I also did some cleaning, cooking and DIYing too!).

I was surfing YouTube for good coding talks and one caught my attention. It was Jack Diederich's PyCon 2012 talk entitled "Stop Writing Classes". I thought I was setting up myself for another OOP basher and functional lover, but then it realized it was 2012: functional was not trendy yet. So I was interested in what he had to say.

It was a brilliant talk. I didn't really agree much with his "less lines of code is better" philosophy. But he had some excellent points about the misuse (overuse) of some OOP features, specifically about namespaces and classes. But the part that struck me was [something he quoted about nine minutes into the talk][video]:

	~ Namespaces are for preventing name collisions, not for creating taxonomies.

That really blew my mind. I felt guilty. I have absolutely misused namespaces basically since I started in OOP. I've done the `use MuffinMail\MuffinHash\MuffinHash` thing. What he is describing is what I've decided to call **Namespaced Taxonomy Syndrome**. Every single PHP project does this thing. It's everywhere.

Take this almost randomly picked example from the `Illuminate` namespace in Laravel: 

```php
use Illuminate\Broadcasting\Broadcasters\Broadcaster;
```

When did we learn to do this? When did we all implicitly agree that doing namespaces this way is somehow the state of the art? Why not go with `Illuminate\Broadcaster`? Is there any other `Broadcaster` inside the `Illuminate` namespace that we can collide with? I think I have some possible explanations.

Taxonomies are useful for organizing. That is the reason we put classes in different folders: to keep them organized. It is the reason why Laravel (and everyone else!) does this. There is a folder called `Broadcasting`, that contains a folder called `Broadcasters` that contains a PHP file that defines the interface `Broadcaster`. Laravel developers need that structure so that code stays separate from other unrelated code. We need the `Broadcasters` folder to know where to find them.

But, by using taxonomies (folders) to organize our code, we silently fell into a trap and we embraced a very wrong assumption: **the assumption that our folder structure must mirror our namespace structure**. This is probably due to the way the [PSR-4 Autoloading Standard][psr4] baked into Composer is commonly used, usually pointing to a single directory and working from there.

```json
{
	"autoload": {
		"psr-4": {
			"MyAwesomeNamespace\\": "src"
		}
	}
}
```

But, when we use composer psr-4 autoload like this we will inevitably use namespaces as taxonomies since we need to keep our code organized. So, how can we solve this? How can we keep things separated still and yet simplify our namespace use?

## A Better Approach

Let's take the `Illuminate` example again. Imagine they have the following directory structure now:

```txt
└── src
    ├── broadcasters
    │   ├── Broadcaster.php         Illuminate\Broadcaster
    │   ├── OtherBroadcaster.php    Illuminate\OtherBroadcaster 
    │   └── LogBroadcaster.php      Illuminate\LogBroadcaster
    └── other-thing
        ├── SomeInterface.php       Illuminate\SomeInterface
        ├── ImplementationOne.php   Illuminate\ImplementationOne
        └── ImplementationTwo.php   Illuminate\ImplementationTwo
```

So, we still have all related code in separate folders to keep things organized. This is the taxonomy part. But notice that the Fully Qualified Class Names of every of these files are all of them direct children of the `Illuminate` namespace. Basically, they are all in the same namespace and that's okay, because the aim of namespaces is to prevent name collisions. There will be no other `Illuminate\Broadcaster` and if there is one, you either taxonomize it in the name itself, or then you can create another namespace to contain it. But not before that.

So, how do we make this file structure work with composer? There are mainly two ways:

The first way is to pass an array of paths to the PSR-4 autoloaded namespace, like this:

```json
{
	"autoload": {
		"psr-4": {
			"Illuminate\\": ["src/broadcasters", "src/other-thing", ]
		}
	}
}
```

What you are saying here to composer is that all of these folders are inside the same namespace. Cool, isn't?
This way, you get the double benefit. First, your code is still organized in different folders to help you reason about it and keep things organized for development. Second, our namespaces fulfil the purpose of avoiding collisions, and for that reason they are easier to use and simpler to reason about.

The second way of doing it is simpler. It does not require to specify every folder. Instead you can just tell composer to build you a *classmap* scanning every single one of your source files.

```json
{
	"autoload": {
		"classmap": "src"
	}
}
```

You can create as many folders as you want in src and organize them and moving them at will. The only thing that matters is that all of them have the same namespace declaration.

If you are a maintainer of a set of packages that share a common namespace, putting all of them in the same namespace reduces the number of imports you need to write. After all, is your namespace. It does make sense that your code lives under the same one. It is also easier for library users to use your code and write the proper inputs.

I'm currently refactoring all my packages to do this. It is a huge breaking change, and maybe popular libraries will most definitely not do this (a very wise choice). But since none of my libraries is extremely popular, I can probably introduce major BC breaks on any of my libraries next major version.

For instance, I'm developing a new Http Framework for PHP powered by a set of components. I'm putting everything http related under `FrameworkName\Http` and everything else under `FrameworkName\Support`. (And even that is using taxonomies a lot!).

## A Note on the Test Namespace

This works really well for testing too. You can put your tests into the same namespace than your source code, but under the `autoload-dev` key in composer. Why is there another namespace for testing? There is no reason to do so. Don't be afraid of:

```json
{
	"autoload": {
		"psr-4": {
			"MyAwesomeNamespace\\": ["src/some-thing", "src/some-other-thing", ]
		}
	},
    "autoload-dev": {
        "psr-4": {
			"MyAwesomeNamespace\\": ["tests/some-thing", "tests/some-other-thing", ]
		}
    }
}
```

## A Note on Reorganizing and Refactoring

Projects grow, and usually the initial folder structure becomes messy, and sometimes we need to move stuff around or rename it to make better sense of it. We all have gone trough that. By putting everything under the same namespace, reorganizing code becomes a matter of creating folders and moving files. Namespaces and references need not to be touched, which gives you a lot of freedom to choose the directory structure that suits you the better.

## A Note on Taxonomies in DDD with Hexagonal Architecture

DDD projects with Hexagonal Architecture are well known for their deeply nested namespace structure. I have one that has a class called `Project\Domain\Model\Account\Account`, and also one called `Project\Infrastructure\Persistence\Account\DoctrineAccount`. That is simply just full-blown taxonomy.

I just need `Project\Account` and `Project\DoctrineAccount`. Nothing else. They could live in totally different folders, but they need not to be in different namespaces. All the things in the middle is just taxonomies to keep things organized. 

You could allow `Project\BoundedContext` just because you could have two account objects in different bounded contexts and they are definitely not the same account. So namespaces fulfil their role here by separating meanings between bounded contexts. But more than that is taxonomy syndrome.

With this method, I can still keep the folders organized in and Hexagonal Architecture way, but keeping the namespace use consistent (and short!) This even helps to fulfil the use of the Domain Language in code.Domain Events and Errors can be in the same namespace too, but in totally different folders, that way we can easily find them.

If you want to separate into packages the different layers, then the package name is your taxonomy: `project/persistence`. When your package is autoloaded, it will bring the persistent implementation of the classes you already have into the same common namespace. It's a win in every side you look at it.

## Conclusion

This is a really good approach to try in your next project. You'll be amazed of the simplicity, the clarity and the freedom that an approach like this will give you. It will make your code simpler, easier to reason about and very flexible to restructuring.

[video]: https://youtu.be/o9pEzgHorH0?t=567
[psr4]: https://www.php-fig.org/psr/psr-4/