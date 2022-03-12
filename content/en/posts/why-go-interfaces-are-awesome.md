---
title: Why Go Interfaces Are Awesome
subtitle: I'm in love with Golang's way of doing interfaces and I think every programming language should do them that way.
categories: ["Tech"]
tags: ["Golang", "Interfaces", "Design"]
draft: false
date: 2021-06-07T00:00:00+01:00
---

After a couple of months of using Go commercially (I've been learning it from about a year now) I can finally have an understanding of the language and the reasoning behind some of the decisions the language authors made when drafting and designing the language.

One of these is interfaces. 

Interfaces in Go are quite special, and they are by far my most loved feature of the language. It is not that I don't know that other languages have interfaces, but they way Go implements them is truly unique and honestly really awesome.

Here is why.

## Go interfaces are behavioral-only

This is something some languages get right too, like PHP. But others like Java or Typescript allow you to define state (properties) in your interfaces too. 

Interfaces should always deal with behavior. Any state, property or any other thing there is really about an implementation detail and should not belong in the interface at all.

This is how you define an interface in Go:

```go
package money

// A Converter takes a pointer to Money and returns another pointer to a
// converted Money, or an error.
type Converter interface {
    Convert(amount *Money) (*Money, error)
}
```

There is nothing here about state nor any implementation detail. An interface is just a set of methods with a predefined signature.

## Go interfaces are implicit

Now, how do I make a type in Go implement the interface declared above? Simply,  by providing that the type in question has the methods defined by the interface with the exact same signature.

```go
package converter

type FixedConverter struct {
    rate float64
}

// This FixedConverter implements the Converter interface.
func (c *FixedConverter) Convert(amount *Money) (*Money, error) {
    return amount.Times(rate), nil
}
```

Note that, a difference with other languages is that we never wrote any `implements` nor we referenced he interface type `Converter` inside our `converter` package. Implementation in Go is **implicit**. You don't explicitly implement an interface: any type that has the method(s) of the interface implements that interface and becomes a Liskov-Substitutable value.

## Go interfaces are zero-coupled

Now, due to this particular property of Go interfaces, we don't need to have a reference to the package where the interface type is defined. Which means that we achieve a zero coupling between the package that uses the interface and the package that implements the interface. Not low coupling: zero.

It's common in other languages like Java or PHP, to have packages containing mostly if not exclusively interfaces. Think about JPA in Java or all the PSRs in PHP. The idea behind this practice is that you only have to couple to the contracts, but not to the implementations, which is a massive gain in decoupling. But in Go interfaces, you don't even have to include the interface package. You can just create another interface in your own package with the same signature and
have your code use that.

This means that libraries now are free to define their own apis and there is not much need for defining a common contract. The code that defines the contract is the code you write, and not some third party.

This is very powerful.