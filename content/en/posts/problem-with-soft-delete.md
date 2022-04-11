---
title: The Problem with Soft Deletes
categories: ["Tech"]
tags: ["Best Practices", "DDD", "Software Development"] 
draft: false
date: 2022-04-11T18:00:00+01:00
---

If you have been in web development for a while you might have stumbled upon
the concept of soft-deletes. Basically, it is a common pattern (or more exactly,
anti-pattern) in database management that allows deleting items from a database
while keeping the records there.

The implementation of this pattern usually involves a nullable timestamp 
column called `deleted_at`. When we delete a record, instead of a `DELETE`
query we just simply run an `UPDATE` one and set that column to the current
timestamp. Then, deleted records can be hidden from the exposed public api by
adding a where clause like the following to every query:

```sql
WHERE deleted_at IS NULL
```

A challenge while implementing this is that this clause must be added globally.
If you are using raw SQL queries this is hard to maintain and error prone. But most
frameworks have robust SQL abstractions that eliminate that issue by using
some plugin or library.

## Benefits & Drawbacks
This technique has some benefits, like the ability to restore records that have been
accidentally removed, keep historical data for reporting purposes and avoid
dealing with referential constraints when deleting records in relational
databases. However, in engineering, not all that is shiny is gold. Although there
are some benefits with this technique, there are also some drawbacks.

The first drawback is that there is a performance penalty your database has to
pay for this. Even if the `deleted_at` column is indexed, still a full table scan
is needed to fetch non-deleted records. This of course harms performance
exponentially as your database table grows. Some people say this is the most
fundamental problem with this approach. I think I tend to agree, although the 
impact of that drawback varies from application to application. 

But, I think there at least two more troubling issues here. One has to do with
referential integrity and another one with domain modeling.

### Soft Deletes obscure referential integrity

When you soft delete a record in your database, none of the foreign key constraints
you have in place will be checked. This is seen as a feature for many. You won't get
any constraint violation errors on any of your queries. Awesome!

The problem is that foreign key constraints are there for a very important reason.
Bypassing them is often unwise. Let's see a concrete example.

Let's think of a `articles` table and a `tags` table. Articles represent blog
posts, and you can tag them with any tag you would like. The relationship between
tags and articles is a many to many one, so you will model this in a `article_tags`
pivot table. Simple. 

Now let's say you go and delete a tag from the system. You get a massive 
**Constraint Violation Error** because that tag is being used in the `article_tags` table
to actually tag some articles. You need to do something with those references
first. Ignoring that kind of problem is never good, because then you could
have inconsistencies in your data model. You should first correct the references
in `article_tags` and then delete the actual tag. 

How to correct the references will depend on your use case or domain. For instance,
when does it make sense to remove a tag? Maybe there is a tag called **DDD** and another
called **Domain Driven Design** in your blog. You want to normalize this, and you
decide that **DDD** will be removed and replaced with **Domain Driven Design**. 
Your delete then should look for the **DDD** tag in `article_tags` and replace
them with the **Domain Driven Design** one, and then you proceed to delete the
**DDD** tag from the `tags` table.

Or maybe you just don't want to normalize anything and just delete a tag and all
of it's references. In that case, you should delete the references first, and then
the actual tags.

It is important that your program has this knowledge baked in itself, because these
are the concepts that power your domain, which takes us to next topic.

    NOTE: Be careful to use Foreign Keys with CASCADE DELETE. They are very convenient,
    but they can massively obscure things and also delete thing you don't want to 
    delete. Again, better to have the knowledge backed in your program.

### Soft Deletes obscure business/domain logic

There are some things in your domain or problem space that will require careful
consideration when it comes to deletion. For instance, in my current company
we offer finance to customers based on something we call a Finance Plan. A finance
plan is just a set of constraints that define the details of a loan (duration, rate,
minimal payment, etc).

Finance plans are then referenced by our applications (these represent credit
applications from customers). 

So, natural question. Should we be able to delete finance plans? Not if we have created
an application with it. Because the finance plan tied to an application now needs
to be kept for historical reasons. We can go even further? Should we be able to 
modify finance plans? No, because any modification to a finance plan would be really
a new finance plan. We don't want to be changing the number of months of an already
approved application, right? If it was approved with 12 months, we can't change that to
13.

Now, what happens when we want to decommission a finance plan? This means, we
want to prevent it for being displayed so applications cannot use it? We just simply take that
concept and convert it into a business action, and we add a column on the database
to track that (`decommissioned_at`). This would work very similarly to the soft
delete column, but now the business action is transparent. It is not a delete,
it is a decommission. And it is not in every entity, just on those that need it.

When we just blindly make everything soft-deletable we obscure these distinctions
and encourage developers to not think about these and other similar issues. This 
hinders domain modelling, as we are thinking more on a CRUD approach rather that
a complex domain.