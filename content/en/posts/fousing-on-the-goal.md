---
title: Focusing on the Goal
subtitle: Empower people to find the method. Just give them the goal.
categories: ["Tech"]
tags: ["Management", "People"]
draft: false
date: 2022-03-12T00:00:00+01:00
---

When I was in school I struggled a lot with math (I still do to be honest!). My results at school were so worrying that my parents hired a private tutor to teach me math. He had a awesome talent to explain complex things in a very clear way, and also taught me different methods to solve equations or other mathematical problems. I was able to see the effect of his teaching pretty quickly, as I improved a lot in the weekly take home exercises. But when the day of the test came, all my hard work seemed to suddenly be meaningless. The professor had told the class that we needed to use the methods he taught us to solve the problems in the final exam. Otherwise, we would be discounted a lot of points even if we reached the correct result. I thought that was so not right.

Probably you had the same experience at school or uni. Or maybe you were blessed and had a teacher who focused more on the outcome rather than in the method. Maybe you were privileged to have a teacher that would show you many different ways of doing things, their pros and cons, and would empower you to choose what would fit better for you.

You would be surprised to know (or maybe not so much) that stories like this repeat a lot in the workplace today, specially in tech companies. Maybe you have seen it for yourself. Maybe the task is to build a REST api, but you need to use this particular database engine, or this particular framework or library. Or maybe you nee to build a payment microservice, but you must not use any form of async communication. Or you should only use docker for development. Or you need to test your code, but using this tool that the company built specifically for that purpose. 

## Method Fixation

Why this fixation of with the method? Isn't that as unjust that this math teacher that forced you to use his particular approach? Why do we constrain people that have one of the highest capacity to learn stuff (Software Developer) to a repeated formula or method? Why not, instead, focus on the desired outcome that we want, instead of telling people how to do stuff?

Some people say that it is for the sake of maintainability. By having "One Right Way of Doing Something" we ensure that we can move people around and replace them if we need to. But I would say that is an illusion. Sounds plausible on paper, but it does not work in real life. There is always a cost of moving one people from one project to another, even when those projects use the exact same stack or underlying framework. They need to learn the ropes anyway, and they might find it hard to become productive quickly.

When I talk about this with some of my colleagues, they freak out. They think I'm advocating for some sort of wild-west IT company where everyone does whatever they want. That could not be more wrong, let me explain.

I'm advocating for a place where people do what are they told to do, but have freedom to choose how they want to get there. Of course, that freedom is limited by some general constraints. For instance, I won't have a guy writing an api on Scala, because we have literally no one at our company that knows it. But, we use PHP, Go and Node quite a lot. I would let her choose and have her explain to me why she would choose that language over the other, just to see how she reasons. Framework? You pick! 

Instead of putting the focus on the process, I desire focus on the outcome. I won't tell her how to do it, but what I expect the end result to be. So, if I ask a developer to write me a REST api, this is my personal desired outcome:

1. Test suite with over 90% coverage
2. Stubbed or mocked unmanaged dependencies directly in code
3. Proper CI Pipeline, testing with even future versions of the language runtime
4. A readme that explains what the api does and how
5. Consistent error handling
6. Excellent Developer Experience (preferably, I should be able to clone the project, run one command and be ready to work and run the test suite)
7. Open Api specification that is reliable

Note how these things don't say **how** you have to build the REST api, but what it should have. The schema is my favorite example. So, should you start with the schema and generate the code? Great, do it that way. Should you write the code and then generate the schema out of it? Works too! As long as the schema accurately represents how the endpoints work, you have my full support!

We can bring this to testing too. Would you write unit tests or full E2E tests? Again, whatever you like, as long as you know the tradeoffs. You can achieve high coverage quickly with E2E tests, specially in large codebases, but tests tend to be more brittle. Unit tests are slower to write but more resistant to change.

Again, the most important thing is that the Engineer chooses her own path to a solution. Of course, inexperienced Engineers would need an overview of the possible paths, but even there I would encourage to explore extra solutions.

## The *Technification* of Tech

This topic is super important to me and a subject I can get very passionate about. And the reason why is that I love Software Development so much, that I refuse to make it a factory profession. I refuse to ask engineers to copy and paste a solution or a template, fill in the blanks and move on to the next thing. How am I doing them a favor? How am I helping them to grow, develop, try new things, be challenged? How am I fostering innovation, thinking outside the box? Did we really put candidates through an interview process focused on evaluating their problem solving skills to have them only repeat a method? How am I empowering them to make their own mistakes and gain experience from them?

Imagine chefs cooking the different dishes using the same recipe, or artists painting with the same technique, or musicians using the same chords and instruments. Restricting any activity that requires creativity is almost a crime. It asphyxiates development in whatever area or field we are working on.

The problem is that in today's highly producer-consumer based society there is no time to be creative. There is no time for the appreciation of a work well done in engineering. Templated, quick solutions are the norm. We are battling the *technification* of technology itself. The latest developments and pushes for low-code, no-code platforms speak of such reality.

It is true. These tools provide massive gains in productivity (if they are flexible enough to support your use case). The problem is that we are raising a generation of Engineers that have just the required high-level notions to use some tool. In such a world, the best Engineers are the ones who go deeper in understanding the low-level notions that power the tools they use. And I want to both further the development of that kind of Engineer and work alongside them.

## Empowering People

When people, specially creative people, are coerced into an automatic way of doing their job, we are doing them a massive damage. We are effectively lowering their value. We are telling them that we believe them incapable of come up with something better and more efficient. Highly creative people will soon leave roles like that. You will be stuck with people that value comfort more than the creative development of their trade.

But then we treat our companies as mere assembly lines of a factory, and equate our workers to machine controllers. It is no secret that factories play a massive role in the alienating the value of individual work. Everyone can move a handle with some degree of coordination. Not everyone can make a machine that does amazing things just by moving a handle with some degree of coordination.

Engineers are not resources. They are people in a highly creative trade. They are not easily replaceable nor interchangeable. They will stay in a place that fosters their creativity and leaves them room to do so. This goes farther than just getting them mere access to a learning platform. They need an outlet for their creativity, they need a blank canvas in which they can try new things and approaches. They need autonomy, and that people in higher places trust them to do a good job. They need to know the whys, not the hows.

This freedom comes with a great responsibility of course. Now, all of a sudden, an Engineer's decision can have a bigger impact in a project or company. And depending of the quality of that decision, the impact can be good or bad. There are two answers to this. (1) If you empower your engineers, they will feel the higher burden of the responsibility they have, and therefore look to do a batter job researching well and providing the best implementation they can. (2) They will make mistakes of course, and bad decisions. We all do, so a good review process whose focus is on guidance is also a good alternative.

If after those two things, still some bad outcomes slip through, a call to remember reality is necessary. We work with people, not gods. We will make mistakes. Make sure to keep empowering the people that, after they do, review their mistakes and are determining to not making them again.