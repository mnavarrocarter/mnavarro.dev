---
title: "Separating Frontend Concerns"
subtitle: How to decouple your business logic from UI frameworks like React, Vue o Svelte.
draft: true
tags:
- nee
date: 2020-05-06T10:00:00-03:00
---

The Javascript world changes fast! Any frontend developer knows that. New technologies in the JS world emerge every year, and some of them with very interesting philosophies, architectural styles and features.

In this fast-changing environment that frontend development is, it is crucial that our applications are designed to change as quickly too. This means, for example, that your application should be able to switch from React to Vue without needing to rewrite the whole thing. Can your application do that?

If your application can't, then let me say this: you have coupled your application (or business logic) to a UI framework. This means that is so entangled with this specific UI framework that you simply cannot get rid of it. This is bad news for your product because, at the pace UI frameworks are changing in JS world, it will become legacy software in about 3-4 years. Nobody wants to invest months of development time, money and effort just to build something that will last for a few years only.

It might be that the change is needed even before. Maybe you started using React, but you realized it was too memory intensive and expensive for mobile or embedded devices, so much it's killing your product in those platforms. You decided to move to Svelte, but the costs of the move are so high that a complete rewrite is the best option.

Maybe you want to extract the core logic of the business to a separate package, so it can be used by other libraries. But you can't: it is absolutely merged with your UI framework.

We must do better, we should want to do better and, good news, we can do better indeed.

## So "How Should We Then Code"

Paraphrasing the title of Francis' Schaeffer [amazing book][schaeffer], we ask the question: "How should we then code our frontend applications so they can be resistant to change?"

In order to answer that question correctly, wee need to remember how frontend applications work. Most of them fetch data from somewhere, process it, display it to a user and allow performing operations with that data based on user's input and actions. The fetching, processing and operating of data is strictly related to what is called business logic. The displaying of data and reacting to user's input and action corresponds to the presentation logic, or what is commonly called the UI.

Reactive UI frameworks like React, Vue, Svelte and others are part of the presentation layer. Their purpose is to help render (display) views (components) using declarative logic. So therefore, they should not contain any logic in themselves that deals with api calls and data processing, which is a business logic concern. Often times this is overlooked because these frameworks also provide constructs for dealing with application logic, like complex state management solutions. Remember, operations on centralized state (data) are part of the business logic, not the presentation logic.

You could argue that state management solutions separate logic from presentation by putting that logic into a store. And it is true. But often times these state management solutions are (1) overcomplicated and (2) can only work with the specific UI vendor (Redux and React, Vuex and Vue, etc). So, the purpose of avoiding vendor lock-in is not entirely fulfilled.

[schaeffer]: https://www.amazon.co.uk/HOW-SHOULD-WE-THEN-LIVE/dp/1581345364