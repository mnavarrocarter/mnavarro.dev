---
title: When to use Interfaces
subtitle: A rant about using and thus, abusing, interfaces for everything
categories: ["Tech"]
tags: ["OOP", "PHP", "Design"]
draft: false
date: 2021-06-07T00:00:00+01:00
---

Not long ago some of my CI pipelines failed in its psalm step. The error was due to an exception that could not be caught, because it was not an exception class. The culprit, the `1.1.1` version of `psr/container`, had removed `extends Throwable` from the `Psr/Container/ContainerExceptionInterface`. [Here is the related issue](https://github.com/php-fig/container/issues/33).

Now, this was all done to a language support issue, which is understandable. But this exposed a somewhat related issue. This would have never happened if the PSR had been designed well from the ground up. For me, part of that bad designed involves the famous and wide-spread use of the so called **error marker interfaces**.

I'm writing this piece not because I want `psr/container` to change, but because I want to raise awareness of this bad practice and eventually convince people writing new library code or refactoring existing library code to dump this approach.

## The Value of Interfaces
Interfaces are probably the building blocks that make object oriented programming one of the best programming paradigms out there. Interfaces are there to **abstract routines** and allowing us to swap different implementations of those routines without even touching client code. That's the power that makes modularity work in object oriented programming. You can replace entire subsystems hidden behind an interface without affecting anything.

The PHP FIG has done tremendous effort on taking some of the most common routines or use cases in PHP and abstract them into interfaces that can be adopted by third party libraries. The purpose of this is to maximize interoperability: if two or more libraries share the same contract or interface, then it is trivial to swap one for another, or even better, building entire subsystems or libraries typing to the interface instead of an implementation means a higher adoption rate.

## The Misuse of Interfaces

Of course, interfaces can be used poorly. If an interface requires us to change client code upon switching implementation, then it becomes what is known as a *leaky abstraction*. If you have to change client code when swapping implementations, then it means the interface leaks implementation details that client code should not be aware of. This is one of the most common issues interfaces have.

Another problem, not so much considered, is making **everything** an interface thinking that by doing so we are providing interoperability. Good object oriented practices dictate that interfaces **should** only be used when (1) we are dealing with service classes and/or (2) we will have two or more possible implementations. By services classes I mean classes that **do** something instead of **representing** something (like value objects or models).

For example, there is little to no value in using interfaces for a value object, unless there are two possible implementations of it. This is the case with the `DateTimeInterface` in PHP. It has an interface because PHP has both a mutable and an immutable implementation. `brick/date-time` is only immutable, so no interface is required.

But other libraries don't get this right. PSR-7 should have been a concrete implementation. This is because literally there is only one possible implementation of it due to the spec being so rigid and opinionated. This would have made adoption much more easier and widespread, eliminate the need for factories and bring so much more benefits to the table.

FIG members usually answer to this by saying that ["FIG creates interfaces and recommendations"](https://github.com/php-fig/container/issues/33#issuecomment-849548872), which is a terrible answer. The the mission of FIG is not making interfaces: the mission is to drive interoperability forward in the PHP ecosystem. They do that by means of interfaces and recommendations, but it is not and should not be the only way. [Some members understand this very well](https://groups.google.com/g/php-fig/c/u2Nmovw_Rlc/m/l8Y_MhIEMgAJ), and others don't.

The *interface only* approach leads to confusion and using interfaces wrongly. One of these uses is using them as error markers, because the assumption is that extending means implementing.And this leads us to the final issue.

## The Fear of Inheritance

**Inheritance is evil** is a common aphorism in Object Oriented world. And with right reason: inheritance couples things, makes changing code harder and could lead to an increase of unexpected breaking changes, because the *not-so-private* api can still be used by other client code.

We all know that the alternative is use of composition. And there is abundant literature, talks and courses that taught it well. No need to repeat common knowledge here.

What I currently see now in the professional PHP ecosystem is not so much now an abuse of inheritance, but a fear of it. We have gone to the other end of the spectrum. 

Part of being a good software engineer is to be able to determine when to use some tool or pattern and when not, based on an informed decision and consideration of the possible future implications.

Using concrete classes for errors in libraries that only contain interfaces is a perfectly reasonable approach. It must be taken with a grain of salt though: implementing custom logic in the exception class is discouraged, because is then when inheritance starts to become a potential issue. On the other side, using interfaces solves no problem at all. What it does is that it creates more work and/or potential confusion for implementors.

So here it is, my rant. Oh, and one more thing. For the love of Pete, stop suffixing your interface names with the word `Interface`. It is useless and repetitive. You don't name your classes `QueueClass`. Why do it with interfaces?