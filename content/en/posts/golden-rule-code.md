---
title: The Golden Rule for Writing Code
categories: ["Tech"]
tags: ["Best Practices", "OOP", "Design Patterns"] 
draft: false
date: 2021-09-26T20:00:00+01:00
---

Every now and then I read a piece about [DRY] vs [WET], explaining their benefits
over its counterpart. Most of the time, these pieces are quite unhelpful, as 
they are way too vague and general. They lack a crucial thing, and that
is  **context**.

I believe this is the most common aspect on disagreements about any topic in
software development. Someone writes a piece about X or Y topic arguing a point,
but then another piece comes up arguing a different case (or sometimes totally
the opposite one). Almost always both authors are presenting valuable and correct
ideas, but their conclusions are different. Why?

I believe this is due to a lack of context, and this happens a lot in the DRY and WET
discussions.

For instance, I read [this article][AHA] that poses yet-another paradigm for dealing
with the problem of when to abstract.

You should absolutely read it. Basically, the author summarized DRY, it's benefits
and problems. Then it summarizes WET's benefits and problems. And then goes on
to present it's own acronymic alternative: AHA.

So, this is the state of the art now in the debate (I'm intentionally reducing the
author's ideas to a few words here):

1. Someone proposed DRY: We should avoid repeated or duplicated code by abstracting it out.
2. Someone proposed WET in reaction: We should wait until the duplication is real. People abstract too early.
3. Someone proposed AHA in response: Even when there is real duplication, you don't know the future. We should wait for the right abstraction.

That's it, in a nutshell. But all this is not helpful at all. There are a lot of
questions left unanswered. Does DRY means I can have no duplicated code at all?
Is all duplication bad? When is it too early to abstract? How can I know when is 
the right time to abstract something away?

Articles don't answer that question, because they can't. And they can't because
the answer is "it depends". Depends of your own particular codebase and problem,
and the context surrounding it. Your problem cannot be reduced to an easy-to-remember
acronym created by a guy who is not dealing with your particular issue.

Proof of this is this wild declaration made by the author of the AHA article. It says
this when it summarizes his approach:

> **I think the big takeaway** about "AHA Programming" is that you shouldn't be dogmatic
> about when you start writing abstractions but instead write the abstraction when
> it *feels* right and don't be afraid to duplicate code until you get there.

That is some terrible advice. The points he raised in his article were all valid,
but the conclusion is just plain terrible. In an attempt to escape from dogmatism
(which is always good), the solution to the problem ends up being reduced to a
mere feeling.

When does it *feel* right to code an abstraction? I don't know, even though in
some of my projects I could have an idea. But most certainly, someone will feel
different.

I think we need a bit more objective advice on how to do this.

# Going Back to the Roots

DRY as an acronym was coined with a purpose. A purpose most people seem to ignore.
Why DRY is good? Because if you have to correct or fix duplicated code in the future,
it will be harder to do, because you will have to change it in the multiple places it was copied.
Why is WET or AHA good? Because if you choose the wrong abstraction and then need to change it, it will be harder
to do so in the future.

For me, there is just only one rule to follow when writing code. Is not an easy one:
most of the time you'll have to figure out the answer and some times you'll get
it wrong. The application of this rule can take many forms and faces, and so it
will require you to be wise. Here it is:

> **Should requirements change in way X, could this code Y be easily changed?**

That's it. There you have it. That is all you need to know for starters. From
that rule, every software principle, every design pattern, every acronym flows.

Of course, like every summarized thing, this rule needs explaining. Let me
break it down in pieces.

## "Should requirements change"

This is kinda obvious. Code changes all the time because of requirements. 
Code is never finished because of requirements. If you have ever done client work
you should know this very well.

In every software project where changes happen, you must be prepared for them. This
requires you to anticipate. Anticipation is one of the most important qualities
of a seasoned developer.

I'm currently learning how to drive and my instructor keeps telling me I'm missing
a very important skill: anticipation. I need to look ahead and be prepared for
possible things that may occur. I need to look at the signs that could cause me
to stop or do another manuever, all the time. He keeps telling me what he has
come to call the golden rule of driving: **we drive not for what is happening, but
for what *could* happen.** I'm just borrowing his wisdom here.

Coding is not much different in that aspect. When coding, **we are not coding just for what we
are asked, but what we *could* be asked.** We need to be aware and read the signs,
and that just takes experience.

If you are in a project in which requirements don't change much or where you are
in full control of them, then none of this applies to you.

## "in ways X"

If you read the rule well, you'll notice there are two variables: X and Y. This
is the first one of them.

I represented the change using a variable because we do not know in which ways
the requirements will change. This seems to contradict my previous point, but it
does not. Let me explain.

One thing is to try to anticipate, another very different one is to know in
advance. Some people confuse the two of them and they say: "Since I cannot know
in advance, it is pointless to anticipate". They couldn't be more wrong.

Only God knows in advance, we agree on that. The purpose of anticipation is not
knowing, is preparing. We read signs of things that might happen so we can be
prepared if they happen. We don't know if they will, but the key verb here is to be
prepared.

You don't know if you are going to lose your job, but nonetheless you try to be
prepared for that by saving up every month. Not knowing in advance does not rule
out being prepared for something unexpected.

Now, here is when you are pretty much on your own, and when context is key. Only
you know in which ways requirements may change. It could be that they ask you
to use another database engine, or support multiple methods of authentication,
or be able to configure certain parts on the system on demand. It could be anything,
but you must always be looking out for the signs.

Usually, when requirements are confusing since the beginning of a project, that's
a very good indication for me when things might change.

## "could this code Y"

So, the second variable subject here is not only the changing requirements, but
the code you are working on that could possibly be impacted by that change of
requirements.

For instance, if a requirement is to convert files to PDF, that is a very good
indication that whatever code you are using to do that, should be properly isolated
so it is easy to change. PDF conversion tools abound out there, and it might happen
that you'll need to change one for another.

For most if these kinds of problems you can get away by coding to an interface.
Define an interface in your application and implement it. The interface should
be small and generic: pass just the enough arguments required to do the conversion.

Then, have your code use the interface. You can be sure it will be easy to change
in the future.

Again, this is a very particular example, but it has a very wide application. Interfaces
are the best way to protect your code from changes. If you design them well,
you will have an easy time swapping the implementation for something else.

Bottom line, you and you only know your code. Be wise.

## "be easily changed"

Now, if the rule were only "Should requirements change in way X, could this code
Y be changed" that would be a terrible rule. The word **easily** is key.

Maybe you come to the conclusion that a potential requirement X could make your
code Y change, so you want to refactor. But the impact is not that big so
leaving it unchanged would still make it easy to refactor should that requirement
X become a reality in the future. In that case, don't change it.

You should only refactor code when the potential of a requirement change will make
it hard to change. Sometimes, changes are not that hard. If a piece of code is 
duplicated in two places, that is not that hard to change. 

Remember, the goal is that we want code that is not hard to change.

# On Picking the Wrong Abstraction

Sometimes, people talk about picking the wrong abstraction early as the worst mistake
you can possibly do.

I've done this so many times, and it is not that terrible at all and quite
simple to correct. I have many stories about this.

I once coded an interface for money conversion in a project I was doing. 
It was very simple. It was called `MoneyConverter` and has one method
`Convert`. It took a `Money` instance and a currency as arguments and returned a
new `Money` instance with the converted amount.

I implemented that using an external api, but that does not matter. This is how
the interface looked:

```php
<?php

interface MoneyConverter
{
    public function convert(Money $money, Currency $currency): Money;
}
```

My client code just used that. Never knew anything about an api or any other implementation
detail.

It was a good idea until someone said "We need to display to the user the conversion
rate in which the conversion was made." Too bad for me, my interface did not
returned that information: it just returned the converted amount. So, I modified
the interface's return argument to be another object called `Conversion` that was
holding two things inside: the `Money` class and the `rate`.

```php
<?php

interface MoneyConverter
{
    public function convert(Money $money, Currency $currency): Conversion;
}

class Conversion
{
    // Original properties were not public. This is just to save space.
    public Money $money;
    public float $rate;
}
```

Now, I had to update every part of the code where the `MoneyConverter` interface
was used (around two or three places) so they were handling correctly the
returned value and then I had to correct the implementation.

Now, two questions.

First one is, could I have anticipated to the requirement? Absolutely! It seemed
something very reasonable to ask and expect. If I ever write a conversion service
again it will always expose this information by default.

Second is, was it a hard change? For me in this project, it wasn't. And I think
here it is where all the fears of coming up with the wrong abstraction come from. It
was very easy for me to spot all the places where I had to change this because
I had all the code using the interface covered with tests, as well as the
implementation using the Api. As soon as I changed the interface and the
implementation, my tests exploded, showing me exactly where and why were failing.
Either myself or any other developer could have made the change, because of the
robust test suite.

The reason why maybe coming up with the wrong abstraction is such a fear, is because
people don't write tests. And tests are essential into making a piece of software
easy to change. Tests are not so much for ensuring correctness of a program: they
exist to help you confidently change your code.

You **will** make wrong decisions when writing code, and sometimes that **will**
lead to disruptive changes. Be prepared for that with a good test suite. Again,
it's all about being prepared.

# Conclusion

Much of the coding best practices and design patterns out there have the sole goal
to make your code easy to maintain by ensuring it is easy to change when it needs 
changing. This is the most important aspect you must keep in mind when writing code,
more than how many times you copy code or if you *feel* it is right to abstract something
or not.

Will this be easy to change is the most important question you can ask yourself
about your code, and only wisdom, experience and good judgement can help you
answer it. Making sure it is easy to change by coding well (DRY, WET, AHA, Design Patterns)
and writing tests is crucial.

[DRY]: https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[WET]: https://dev.to/nettab/we-should-all-be-writing-wet-code-3d95
[AHA]: https://kentcdodds.com/blog/aha-programming?s=09
