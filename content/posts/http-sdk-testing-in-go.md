---
title: Testing HTTP SDKs in Golang
subtitle: Some thoughts on how to test code that integrates with third party HTTP services and apis
tags: 
    - testing
    - golang
    - http
draft: false
date: 2021-09-08T20:00:00+01:00
---

How do you test code that integrates with a third party HTTP service? 

# The Philosophical Answer

If you think about it, it is not an easy question to answer. Maybe you have already some strong opinions formed about it. But, in my experience, answers to this question differ greatly among developers, even between seasoned ones. 

I believe those differences are due to some preconceived ideas or different definitions about what testing is. For example, some people believe that testing is making sure your code works. The problem with that definition is that it is too vague; "it works" can mean anything.

![works-on-my-machine](https://blog.sergeyev.info/images/works-on-my-machine/the-line.jpg)

Take, for instance, the following (too familiar) situation: you are told to code a service (or SDK) that integrates with a third party api or http service. As is usual with integrations, confusing or incomplete specs are passed around. Nonetheless, that is sufficient to do your job. You decide to test creating a mock server based on the spec and build your suite to a very good coverage. So far so good. 

But, when the day comes to do some acceptance testing against the QA environment of the service you are integrating to, you realized nothing worked. Turns out services needed an extra header that was not included in any spec. No problem though; you add it to the code, update your tests and move forward.

I'll come back to this story to explore other relevant topics later. For now, I want to use it to ask you a question. Would you say that the initial version released to test against QA "worked"? Well, it's a tricky one, isn't it? It did not worked in the sense that it did not integrate correctly because of the missing header. It worked in the sense that the program did what it was coded to do with the available knowledge at the time.

Based on this, I would like to make the main point of this article, from which every other point flows. **Testing is not making sure your program does something correctly; testing is making sure your program does what the code says it does.** In our previously mentioned story, we cannot ensure a correct integration until we have hit a real service (and not a mock), but we can have good tests that ensure the program is doing what we have coded it to do.

I think the distinction of these two is greatly accentuated in integrations with third party http services. Unless you have an spec that is automatically generated from the service code, until you start hitting endpoints, you can never know for sure if you have integrated correctly or not.

In my opinion, the sooner we embrace this reality, the better. Once we do, we will be able to go and ask ourselves the next question.

## What then do we test?

So, if we cannot test that our SDK integrates correctly with the service. What do we test then? The answer is: **we test that our code follows what we understand of the specification we were given.**

For instance, if the specification says that we should send an `Authorization` header with some sort of token, we test that (1) A request is created containing the `Authorization` header and (2) that the passed token value is indeed the same that is injected in the header. Similar principles follow for URL, method and body.

The following of a specification does not have to do only with an expectation about the request, but also a correct handling of a response. This means we should also test that our code follows the specification when handling responses. 

We should map status codes to certain errors, or react to different content types, or deserialize certain payloads to some types without data loss, etc. We should test that our code does this based on the spec.

Okay, I'm sure you are getting very impatient and want to get to the "how" of testing a third party http integration. Just allow me to say one more thing.

## What are we not testing?

Many developers understand all that I've written. So, they take their keyboards and decide that the best way to test the aforementioned things is just by spinning up a temporary web server process, listening in a random port, that is pre-configured to respond to requests mapping certain methods and urls to certain responses. Most people call this a *mock server*.

No blame on them! I've seen this approach being endorsed by really prominent Go developers. And I think it is specially prominent in Go due to the fact that it is indeed very easy to spin up a server in a separate Goroutine.

However, this approach is often unnecessary and overly complex. Let me explain why.

### We are not testing TCP/TLS/HTTP!

First, there is no send our `*http.Request` over a TCP socket to a server, have the server parse the request and end up with a `*http.Request` again in a completely different process, that will be passed to a handler that will match our request and return a response.

```txt
http.Request --> Http Client --> TCP Socket --> Server --> Http Parser --> http.Request --> handler -> http.Response
```

We can simplify this massively, bypassing all the TCP, server stuff and just doing stuff in memory, in a function.

```txt
http.Request -> function -> http.Response
```

And this is fine, because we are not testing TCP, nor TLS, nor the HTTP protocol. The Go standard library already has tests for all those packages and functions. We care to test *our* code.

So, it is absolutely unnecessary to use a real http request to mocked server to test that our code complies to a spec.

Plus, something happens with that server, it will be really hard to debug.

### We are not testing routing!

Even when not using server over TCP mocking techniques, but in memory ones, some people still go with building some kind of in-memory testing "server" that returns responses based on some matching logic. Usually this takes the form of matching the method and the url.

Again, this is completely unnecessary, and it could lead to undesirable side-effects in testing, plus a couple of more issues.

It is unnecessary because, remember, we are testing that our code conforms to a spec. In other words, we are testing that we send a request with the correct contents and that we are capable to handle certain responses. We are not testing routing (that a request with a certain method and URL with gives us a certain response).

This approach usually leads to side effects. Since this massive, respond-to-everything, in-memory mock of a server needs to be configured somewhere, it usually is outside the tested code. If someone changes an id, or accidentally creates another request with the same url.

Also, there is no clear contract to what should be the response when a request of this mock cannot be matched. This usually weakens error handling code.

Moreover, a mock like this ignores the fact that some HTTP operations are not idempotent: the same method and url combination can and will give different answers based on the internal state of the server at the time of the call. It is really hard to mock that using this approach.

It's better not to try to play any matching games and do something deterministic and single use.

# The Practical Answer

Now that I have ranted enough about these things, is time I explain my proposed approach.

Let's suppose that we have an third party service with an endpoint `POST /input`. This endpoint takes a `application/json` payload that only contains
one key `message`, and can be an string of any length.

The service returns an `application/json` payload with the same structure: again, the object with a `message` key.

This is how I would implement it in Go. Read the comments so you get a better understanding.

```go
package fakesdk

// A main client struct to hold everything together
type FakeApiClient struct {
	client  HTTPClient
	baseUrl string
}

// A constructor to make that client with good defaults
func NewFakeApiClient(baseUrl string) *FakeApiClient {
    return &FakeApiClient{
        client: http.DefaultClient,
        baseUrl: baseUrl
    }
}

// Some people like to make an interface with the same signature
// as http.Client.Do function so they can swap implementations for
// testing. http.RoundTripper can do this already, but well, 
// everyone has their own preference. 
type HTTPClient interface {
	Do(req *http.Request) (*http.Response, error)
}

// This creates the request. Pretty standard stuff here.
// The only detail is that we need to serialize from json and make
// sure we put the right content type.
// Oh, and that we pass the context to the request!
func (cl *FakeApiClient) mustMakeRequest(ctx context.Context, method, path string, input interface{}) *http.Request {
	var body io.Reader

	if input != nil {
		b, err := json.Marshal(input)
		if err != nil {
			panic(err) // Developer error
		}
		body = bytes.NewBuffer(b)
	}

	url := cl.baseUrl + path

	req, err := http.NewRequest(method, url, body)
	if err != nil {
		panic(err) // Developer error
	}

	req.Header.Add("Content-Type", "application/json")

	return req.WithContext(ctx)
}

// The fake input struct
type FakeInput struct {
	Message string `json:"message"`
}

// The fake output struct
type FakeOutput struct {
	Message string `json:"message"`
}

// This is the actual method that will be used in client code.
// Pretty standard stuff too. Sends the request and handles any error.
// Also decodes the payload.
func (cl *FakeApiClient) PostInput(ctx context.Context, input *FakeInput) (*FakeOutput, error) {
	req := cl.mustMakeRequest(ctx, "POST", "/input", input)

	res, err := cl.client.Do(req)
	if err != nil {
		return nil, err
	}

	defer res.Body.Close()

    if res.StatusCode >= 400 {
        return nil, errors.New("server responded with code %d", res.StatusCode)
    }

	out := &FakeOutput{}

	err = json.NewDecoder(res.Body).Decode(out)
	if err != nil {
		return nil, err
	}

	return out, nil
}
```

Now, the only thing I need to test is that I send the correct request and I'm capable to handle all possible responses. That's it. Nothing else.

Sending the the correct request in this case means that the method is correct, the url too, that the body gets serialized to json correctly and that the compulsory headers are present and with the correct values.

Being capable to handle all possible responses means that I should code expectations for when my code fails. For instance, if I get a response with a status code 400, then my code should return an error saying "server responded with code 400". 

Now, doing all these checks on the request and building all the responses for every test case would be very verbose. Luckily, I've created a package just for that. It is called `httpclientmock`. It is extremely simple and straight forward, and you are meant to use it in your test suites like this:

```go
package fakesdk_test

var postInputTests = []struct {
	name       string
	input      *FakeInput
	mock       *httpclientmock.Mock
	assertions func(t *testing.T, output *FakeOutput, err error)
}{
	{
		name:  "test one",
		input: &FakeInput{"This is a message sent"},
		mock: &httpclientmock.Mock{
			Expect: &httpclientmock.Request{
				Method: "POST",
				Url:    "https://some.fake.service/input",
				Headers: map[string]string{
					"Content-Type": "application/json",
				},
				Body: []byte(`{"message":"This is a message sent"}`),
			},
			Return: &httpclientmock.Response{
				StatusCode: 200,
				Headers: map[string]string{
					"Content-Type": "application/json",
				},
				Body: []byte(`{"message":"This is a message received"}`),
			},
		},
		assertions: func(t *testing.T, output *FakeOutput, err error) {
			if output == nil {
				t.Error("no output")
			}
			if err != nil {
				t.Error("an error has happened")
			}
		},
	},
}

func TestPostInput(t *testing.T) {
	client := &FakeApiClient{http.DefaultClient, "https://some.fake.service"}
	for _, test := range postInputTests {
		t.Run(test.name, func(t *testing.T) {
            // Inject in client mutates http.DefaultClient transport.
            // The restore function restores the previous transport.
			restore := test.mock.InjectInClient(t, nil)
            // We defer the restoring of the previous transport when the test finishes
			defer restore()
            // Pass the input
			out, err := client.PostInput(context.Background(), test.input)
			// Assert about the output
            test.assertions(t, out, err)
		})
	}
}
```

The benefits of using this library are huge. First, its ability to modify `http.DefaultClient` responsibly means you don't need to worry about dependency injection too much when setting up tests that send requests very deep in the call stack. So, you could use it for E2E tests without a problem. 

If you wish to use better practices like dependency injection, no problem, we got you covered. `httptestmock.Mock` has a method called `BuildNewClient` that will give you a `*http.Client`. You can also call `GetTestFunc` and this
will give you a `TestHttpFunc`, which is a type that implements `http.RoundTripper` and another function that has the same signature than `Do` in `http.Client`. You can integrate this library into your code in all these ways.

You are probably thinking "Oh this thing modifies the global `http.DefaultClient`. That could cause massive side effects" And yes, you are correct. This is why `InjectInClient` returns a function. Calling it will restore the state of the client to what it was before the test. And you must make sure to defer that, so no other tests can potentially be affected by the mutation.

You can keep on adding more tests in the block, with different payloads and different responses, writing expectations for every case. All the information of the test is in the test itself. No need to chase other files or look in logs from another process.

Also, no side effects. All the state of the world lives there in your test run. Your response will be what the `Return` property indicates will be. No surprises.

## Learn By Looking

If you need a more comprehensive example. You can take a look at [this library I'm building][go-transbank]. It's an SDK for a third party http service from Chile called Transbank. One of it's services, Webpay, allows you to integrate with their payment gateway. [I'm using `httpclientmock` to test the integration][test].

[go-transbank]: https://github.com/mnavarrocarter/transbank

[test]: https://github.com/mnavarrocarter/transbank/blob/main/webpay/create_test.go