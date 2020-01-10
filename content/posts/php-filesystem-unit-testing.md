---
title: Unit-testing the filesystem in PHP
draft: false
date: 2019-12-16T11:18:48-03:00
tags:
    - unit-testing
    - php
    - filesystem
    - stream-wrappers
---

I used to be a big fan of filesystem abstractions, not only for the abstraction benefit, but also for the testing benefit as well. It is trivial to unit test classes depending in filesystem abstractions like [Flysystem][1] or [Gaufrette][2]: just a simple mock of the interface and we are done.

However, from time to time I was kinda annoyed with some limitations of the abstractions, specially in regards to stream handling. I started to get dissapointed of them and started looking at simpler approaches. For instance, PHP supports filesystem abstractions natively in the form of **stream wrappers**. If you don't know about them, you should really [take a look at them][3]!

But there was just one thing that prevented me from going all-in with PHP stream wrappers, and this is that they are really complex to test, because they imply to hit the real filesystem since you cannot mock php filesystem functions.

Well, it turns out not really. Actually, what if I told you that you can use PHP stream wrappers to create an in-memory filesystem for testing purposes? Actually, you don't even have to create it, because it already exists! 

[`adlawson/vfs`][4] implements such filesystem, which is commonly called a *virtual filesystem*. They way you use it it's very similar to using a mock. You create the filesystem and leave it in the state you want for your tests. For example, here's a test from one of the Espresso packages where I use it:

```php

$templateEngineMock = $this->createMock(TemplateEngineInterface::class);
$transformerMock = $this->createMock(TransformerInterface::class);
$mimeTypesMock = $this->createMock(MimeTypes::class);

// Setting up virtual FS
$fs = FileSystem::factory('vfs://');
$fs->mount();
// We create a new directory with some files in it
$dir = new Directory(['bar' => new File('Some file with no extension')]);
// Then we add the directory to the fs
$fs->get('/')->add('foo', $dir);

$mimeTypesMock->expects($this->once())
    ->method('getMimeType')
    ->with('')
    ->willReturn(null);

$simpleResponse = new SimpleResponse($templateEngineMock, $transformerMock, $mimeTypesMock);
$response = $simpleResponse->withDownload('vfs://foo/bar'); // Here we use it
```

Once we have set up the filesystem, we can use the `vfs://` stream wrapper like any other stream wrapper. This way, we can test behavior without hitting a real filesystem, what makes our test a truly unit one.

Make sure you start testing the code depending on PHP native filesystem functions this way. You'll see it's a lot easier to work with, and way more reliable.

[1]: https://flysystem.thephpleague.com/docs/
[2]: https://github.com/knplabs/Gaufrette
[3]: https://dzone.com/articles/the-powerful-resource-of-php-stream-wrappers
[4]: https://github.com/adlawson/php-vfs