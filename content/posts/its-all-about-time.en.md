---
title: It's all about time
subtitle: Lessons learned on building a multi-tenant booking system in PHP.
tags: 
    - php
    - coding
    - time
draft: true
date: 2020-07-20T20:00:00+01:00
---

In Spatialest we provide services to US counties in the property appraisal domain. One of those services is called "Meetings". It allows taxpayers to book an informational meeting with some county staff from the comfort of their homes with the purpose of discussing details of their property valuation.

We have clients across all US timezones, so our booking system must be timezone aware. On top of that, some US timezones are really weird. Arizona, for instance, is inside the Mountain time but they do not observe DST, which affects future dates calculations.

We also use a service to generate booking availability (time-slots) based on certains rules, like start-end dates, time windows during the day (from 09:00 to 12:00 and 13:00 to 17:00) and exlcuding certain dates.

Testing and QA processes noted several inconsistencies when booking in different contexts. Some times were offs, others not rendering correctly, and some other issues. We learned a ton of lessons on how to work with dates in the process. Here are some of the lessons learned:

## 1. Prefer Objects, not Timestamps
**TLDR; Objects contain apis that make it easier to perform some actions in your dates and make your code more consice and readable.**

A timestamp is the number of seconds since the unix epoch (1 January 1970 at 00:00:00 UTC) represented as a 32 bit integer (in most systems). This is a very convienient representation for storage, but it is not a good representation for software manipulation.

Calculating the number of days between two timestamps can quickly become tricky, or adding/removing the neccesary seconds to transform that timestamp to another timezone. Formatting is also pretty tricky.

Most languages have decent enough standard libraries that provide a `Date` or a `DateTime` object. Learning their apis and their quirks is fundamental for you as a developer.

My personal recommendation for PHP is to go with `cakephp/chronos` due to it's immutability and rich api. One that has me very fascinated though is `brick/date-time` because it is very compliant with ISO 8601 and provides constructs that are very well designed.

So, go ahead and store your dates as timestamps, but make sure that between that storage layer and your application there is a transformation of that `int32` into something more useful and with a good api. Your client code will be grateful.

## 2. Prefer Immutable Objects
**TLDR; Immutable objects make you aware of the fact that modifying time results really in a different time object altogether.**

I sort of touched on this one already. Inexperienced PHP developers will almost always use `DateTime` for working with dates, without knowing too much about how objects work and how they are passed (by reference). So some other code modifies the reference and that can have horrible side-effects.

Those side-effects get always noticed when you want to add/substract intervals from a date. You would expect `$date` not to change, but it does. This is due to it's mutability.

```php
$date = new DateTime('2021-04-05');
$after = $date->add(new DateInterval('P4D'));
echo $date->format('Y-m-d'); // 2021-04-09
echo $after->format('Y-m-d'); // 2021-04-09
```

For better way of comparing mutability vs immutabiluty, check this [sandbox code](https://bitter-cake-qog6.ciroue.com/).

For value objects that are critical to operate correctly, like `Money` or `DateTime`, I will always favour immutabiluty above any other solution that does not use it. Moreover, if the solution involves *only* immutable values, that is better. It means there is no way of using it wrong.

## 3. Understand that time is relative
**TDLR; Time is relative to a place (timezone). When having a date and time with no timezone you must always ask: "Where?".**

I'm a Chilean living in the UK, so I know very well that time is relative. When I'm coordinating calls with friends back home I'm always very careful to say something like "let's talk this Friday at 9:00 PM, **my time**". 9:00 PM in the UK is not the same instant that 9:00 PM Chile. The distinction then is neccesary to avoid confusion.

In the same way, when passing time information around, like "I want to book a meeting on Nov 1st, 9:00 AM", always ask "9:00 AM where?". That is very important. If you forget that, your system will probably assume you mean UTC, and that's pretty bad if you meant Mountain Time in the US. We don't like assumptions about time in a Zoom call across oceans. The same is true for computing systems.

## 4. Use named Timezones, not offsets
**TLDR; Named timezones are aware of DST. Offsets are not.**

Date and Time libraries are one of the most useful libraries ever to be coded. Let me give you an example:

You have a unix timestamp. You know that timestamp is in UTC, and you want to convert it into New York's time. You google "New York Time" and you get 5 hours less than your current time. So you do the math::

```php
<?php

$timestamp = 1616096657;
$converted = $timestamp - (5*3600);
```

The problem is that some time around mid march, customers start complaining that they were getting one hour later to their meetings. This is because after march 18th, New York moves to GMT -4 because of daylight saving time. So there are not 5 hours of difference anymore, but 4.

DateTime libraries solve this issue in the only possible way: by mantaining a database of timezone offsets and daylight saving times for especific timezones, with rules that apply to them. Those timezones are assigned a name and published so everyone can access that information. [The IANA mantains this database](https://www.iana.org/time-zones), and when a country changes their DST policy, it is updated in the database.

Every country changes DST in different moments of the year, and some other zones don't even observe DST. All these rules are already backed into the DateTime libraries for you, so you don't have to determine those by yourself.

It is thanks to them that your computer can correctly substract time in between timezones at any moment of the year. So remember to use this named zones, because

## 5. Store everything in UTC
TLDR; Some persistence engines do not support timezones. Better to transform everything to UTC before saving.

## 6. Transfer everything in ISO 8601 format
TLDR; To avoid assumptions about locales to interfere with your system (like DD/MM/YYYY vs MM/DD/YYYY) an unambiguous and well supported representation of a moment in time should be used.

## 7. Present information in your client's timezone
TLDR; Showing the right timezone to the client is a display concern. Do it in the view.

## 8. Don't be afraid of in-memory manipulation
TLDR; Sorting, filtering and reducing can be done extremely quickly and very easily in Javascript. Also, use the `Map` object for quick lookups.