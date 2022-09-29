# Swift-Concurrency

## Table of contents

- Introduction

* [Concurrency vs parallelism](#Concurrency-vs-parallelism)
* [Understanding threads and queues](#Understanding-threads-and-queues)
* [Main thread and main queue](#Main-thread-and-main-queue)
* [Where is Swift concurrency supported?](#Where-is-Swift-concurrency-supported)

- Async/await

* [What is a synchronous function?](#What-is-a-synchronous-function)
* [What is an asynchronous function?](#What-is-an-asynchronous-function)


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


# Async/await


## What is a synchronous function?

- By default, all Swift functions are `synchronous`.

- A `synchronous` function is one that executes all its work in a simple, straight line on a single thread.

- `synchronous` functions are very easy to think about: when you call function A, it will carry on working until all its work is done, then return a value.

- If while working, function A calls function B, and perhaps functions C, D, and E as well, it doesn’t matter – `they all will execute on the same thread`, and run one by one until the work completes.

- Internally this is handled as a `function stack`: whenever one function calls another, the system creates what’s called a `stack frame` to store all the data required for that new function – that’s things like its local variables, for example. 

- That new `stack frame` gets pushed on top of the previous one, like a stack of Lego bricks, and if that function calls a third function then another `stack frame` is created and added above the others. 

- Eventually the functions finish, and their `stack frame` is removed and destroyed in a process we call `popping`, and control goes back to whichever function the code was called from.

- `Synchronous` functions have an important downside, which is that they are `blocking`. 

- If function A calls function B and needs to know what its return value is, then function A must wait for function B to finish before it can continue.

- `blocking` code is problematic because now you’ve `blocked a whole thread`.

- Although `synchronous` functions are easy to think about and work with, they aren’t very efficient for certain kinds of tasks. 

- To make our code more flexible and more efficient, it’s possible to create `asynchronous` functions instead.


## What is an asynchronous function?

- Swift functions are `synchronous` by default, we can make them `asynchronous` by adding one keyword: `async`.

- Inside `asynchronous` functions, we can call other `asynchronous functions` using a second keyword: `await`.

- As a result you will hear Swift developers talk about `async/await` as a way of coding.

- `Synchronous` function that rolls a virtual dice and returns its result:

```swift
func randomD6() -> Int {
    Int.random(in: 1...6)
}

let result = randomD6()
print(result)
```

- `Asynchronous` function that rolls a virtual dice and returns its result:

```swift
func randomD6() async -> Int {
    Int.random(in: 1...6)
}

let result = await randomD6()
print(result)
```

- The only part of the code that changed is adding the `async` keyword before the return type and the `await` keyword before calling it.

- Those changes tell us three important things about `async` functions:


1- First, `async` is part of the function’s type. 

- The original, `synchronous function returns an integer`, which means we can’t use it in a place that expects it to return a string, by marking the code `async` we’ve now made it an `asynchronous function that returns an integer`, which means we can’t use it in a place that expects a `synchronous function that returns an integer`.

- The `async` nature of the function is part of its type: it affects the way we refer to the function everywhere else in our code.

- This is exactly how `throws` works – `you can’t use a throwing function in a place that expects a non-throwing function`.


2- Second, notice that the work inside our function hasn’t actually changed. 

- The same work is being done as before: this function doesn’t actually use the `await` keyword at all, and that’s okay. 

- You see, marking a function with `async` means it might do `asynchronous work`, not that it must. 

- Again, the same is true of `throws` – some paths through a function might throw, but others might not.


3- A third key difference arises when we call randomD6(), because we need to do so `asynchronously`. 

- Swift provides a few ways we can do this, but in our example we used `await`, which means `“run this function asynchronously and wait for its result to come back before continuing.”`

- So, what’s the actual difference between `synchronous` and `asynchronous` functions we can demostrate it using a real function that does some `async` work to fetch a file from a web server:

```swift
func fetchNews() async -> Data? {
    do {
        let url = URL(string: "https://hws.dev/news-1.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    } catch {
        print("Failed to fetch data")
        return nil
    }
}

if let data = await fetchNews() {
    print("Downloaded \(data.count) bytes")
} else {
    print("Download failed.")
}
```

- `URLSession.shared.data(from:)` method is called `asynchronous` – its job is to fetch some data from a web server, without causing the whole program to freeze up.

- We’ve already seen that `synchronous` functions cause `blocking`, which leads to performance problems. 

- `Async` functions do not block: when we call them with `await` we are marking a `suspension point`, which is a place where the function can suspend itself – literally stop running – so that other work can happen. 

- At some point in the future the function’s work completes, and Swift will wake it back up out of its “suspended animation”-like existence and it will carry on working.

- First, when an `async function is suspended`, all the `async functions that called it are also suspended`; they all wait quietly while the `async work happens`, then resume later on. 

- This is really important: `async functions have this special ability to be suspended` that `regular synchronous functions do not`. 

- It’s for this reason that `synchronous functions` cannot call `async functions` directly – they don’t know how to suspend themselves.

- Second, a function can be suspended as many times as is needed, but it won’t happen without you writing `await` there – functions won’t suspend themselves by surprise.

- Third, a `function that is suspended does not block the thread it’s running on`, and instead `it gives up that thread so that Swift can do other work instead`. 

- Note: Although we can tell Swift how important many tasks are, we don’t get to decide exactly how the system schedules our work – it automatically takes care of all the threads working under the hood. 

- This means if we call `async function A` without waiting for its result, then a moment later call `async function B`, it’s entirely `possible B will start running before A does`.

- Fourth, when the function resumes, it might be running on the same thread as before, but it might not.

- Swift gets to choose, and you shouldn’t make any assumptions here. 

- This means by the time your function resumes all sorts of things might have changed in your program – a few milliseconds might have passed, or perhaps 20 seconds or more.

- And finally just because a function is `async` doesn’t mean it will suspend – the `await keyword` only `marks a potential suspension point`.

- Most of the time Swift knows perfectly well that the function we’re calling is `async`, so this `await` keyword it’s `a way of clearly marking which parts of the function might suspend`, so you can know for sure which parts of the function run as one atomic chunk.

- “Atomic” means “indivisible” – a chunk of work where all lines of code will execute without being interrupted by other code running.

- This requirement for `await` is identical to the requirement for `try`, where we must mark each line of code that might throw errors.

- `Async` functions are like regular functions, except if they need to, they `can suspend themselves and all their callers, freeing up their thread to do other work`.

