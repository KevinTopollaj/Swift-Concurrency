# Swift-Concurrency

## Table of contents

* [Concurrency vs parallelism](#Concurrency-vs-parallelism)
* [Understanding threads and queues](#Understanding-threads-and-queues)
* [Main thread and main queue](#Main-thread-and-main-queue)
* [Where is Swift concurrency supported?](#Where-is-Swift-concurrency-supported?)


# Introduction


## Concurrency vs parallelism

- Concurrency is about dealing with many things at once.
- Parallelism is about doing many things at once.

- Concurrency is a way to structure things so you can maybe use parallelism to do a better job.


## Understanding threads and queues

- Every program launches with at least one thread where its work takes place, called the `main thread`.

- That initial thread – the one the app is first launched with – always exists for the lifetime of the app, and it’s always called the `main thread`.

- This is important, because all your user interface work must take place on that `main thread`.

- If you try to update your UI from any other thread in your program you might find nothing happens, you might find your app crashes, or pretty much anywhere in between.

- Swapping threads is known as a `context switch`, and it has a performance cost: the system must stash away all the data the thread was using and remember how far it had progressed in its work, before giving another thread the chance to run.

- Apart from that `main thread` of work that starts our whole program and manages the user interface, we normally prefer to think of our work in terms of `queues`.

- We create a queue and add work to it, and the system will remove and execute work from there in the order it was added.

- Sometimes the `queues are serial`, which means they remove one piece of work from the front of the queue and complete it before going onto the next piece of work.

- Sometimes they are `concurrent`, which means they remove and execute multiple pieces of work at a time.

- Either way work will start in the order it was added to the queue unless we specifically say something has a high or low priority.

- Sometimes `serial queues` are required to ensure our data is safe, because it stops you from trying to read the data at the same time some other part of your program is trying to write new data.

- `Threads` are the individual slices of a program that do pieces of work.

- `Queues` are like pipelines of execution where we can request that work can be done at some point.


## Main thread and main queue

- `Main thread` is the one that starts our program, and it’s also the one where all our UI work must happen.

-  Your `main queue` will always execute on the `main thread` and is therefore where you’ll be doing your UI work, it’s also possible that `other queues` might sometimes run on the `main thread` – the system is free to move things around in whatever way is most efficient.

- If you’re on the `main queue` then you’re definitely on the `main thread`.

- Being on the `main thread` doesn’t automatically mean you’re on the `main queue`, a different queue could temporarily be running on the `main thread`.


## Where is Swift concurrency supported?

- When it was originally announced, Swift concurrency required at least `iOS 15`, macOS 12, watchOS 8, tvOS 15, or on other platforms at least `Swift 5.5`.

- If you’re building your code using `Xcode 13.2` or later you can back deploy to older versions of each of those operating systems: `iOS 13`, macOS 10.15, watchOS 6, and tvOS 13 are all supported. 

- This offers the full range of Swift functionality, including `actors`, `async/await`, the `task APIs`, and more.

- This backwards compatibility applies only to Swift language features, not to any APIs built using those language features.

- If you are keen to use the newer APIs in your project while also preserving backwards compatibility for older OS releases, your best bet is to `add a runtime version check for iOS 15` then wrap the older APIs with `continuations`.

- This kind of hybrid solution allows you to keep using `async/await` elsewhere in your project – you get all the benefits of concurrency for the vast majority of your code, while keeping your backwards deployment shims neatly organized in one place so they can be removed in a year or two.



