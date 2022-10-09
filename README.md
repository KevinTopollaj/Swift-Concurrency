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
* [How to create and call an async function](#How-to-create-and-call-an-async-function)
* [How to call async throwing functions](#How-to-call-async-throwing-functions)
* [What calls the first async function?](#What-calls-the-first-async-function)
* [What is the performance cost of calling an async function?](#What-is-the-performance-cost-of-calling-an-async-function)
* [How to create and use async properties](#How-to-create-and-use-async-properties)
* [How to call an async function using async let](#How-to-call-an-async-function-using-async-let)
* [What is the difference between await and async let?](#What-is-the-difference-between-await-and-async-let)
* [Why we can not call async functions using async var?](#Why-we-can-not-call-async-functions-using-async-var)
* [How to use continuations to convert completion handlers into async functions](#How-to-use-continuations-to-convert-completion-handlers-into-async-functions)
* [How to create continuations that can throw errors](#How-to-create-continuations-that-can-throw-errors)
* [How to store continuations to be resumed later](#How-to-store-continuations-to-be-resumed-later)
* [How to fix the error “async call in a function that does not support concurrency”](#How-to-fix-the-error-async-call-in-a-function-that-does-not-support-concurrency)

- Sequences and streams

* [What is the difference between Sequence AsyncSequence and AsyncStream?](#What-is-the-difference-between-Sequence-AsyncSequence-and-AsyncStream)
* [How to loop over an AsyncSequence using for await](#How-to-loop-over-an-AsyncSequence-using-for-await)
* [How to manipulate an AsyncSequence using map() filter() and more](#How-to-manipulate-an-AsyncSequence-using-map()-filter()-and-more)

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


## How to create and call an async function

- Using `async functions` in Swift is done in two steps: 

1. Declaring the function itself as being `async`. 

2. Calling that function using `await`.

-  If we were building an app that wanted to:

1. Download a whole bunch of temperature readings from a weather station. 

2. Calculate the average temperature.

3. Upload those results

- We might want to make all three of those async:

1. Downloading data from the internet should always be done `asynchronously`, even a very small download can take a long time if the user has a bad cellphone connection.

2. Doing lots of mathematics might run quickly if the system is doing nothing else, but it might also take a long time if you have complex work and the system is busy doing something else.

3. Uploading data to the internet suffers from the same networking problems as downloading, and should always be done `asynchronously`.

- To actually use those functions we would then need to write a fourth function that calls them one by one and prints the response. 

- This function also needs to be `async`, because in theory the three functions it calls could suspend and so it might also need to be suspended.

```swift
func fetchWeatherHistory() async -> [Double] {
    (1...100_000).map { _ in Double.random(in: -10...30) }
}

func calculateAverageTemperature(for records: [Double]) async -> Double {
    let total = records.reduce(0, +)
    let average = total / Double(records.count)
    return average
}

func upload(result: Double) async -> String {
    "OK"
}

func processWeather() async {
    let records = await fetchWeatherHistory()
    let average = await calculateAverageTemperature(for: records)
    let response = await upload(result: average)
    print("Server response: \(response)")
}

await processWeather()
```

- So, we have three simple `async functions` that fit together to form a sequence: `download some data`, `process that data`, `then upload the result`. 

- That all gets stitched together into a cohesive flow using the `processWeather()` function, which can then be called from elsewhere.

- That’s not a lot of code, but it is a lot of functionality:

- Every one of those `await` calls is a `potential suspension point`, which is why we marked it explicitly. Like I said, one `async function` can `suspend as many times as is needed`.

- Swift will run each of the `await` calls `in sequence`, waiting for the previous one to complete. This is not going to run several things in parallel.

- Each time an `await` call finishes, its final value gets assigned to one of our constants – `records`, `average`, and `response`. 

- Once created this is just regular data, no different from if we had created it `synchronously`.

- Because it calls `async functions` using `await`, it is required that `processWeather()` be itself an `async function`. If you remove that Swift will refuse to build your code.

- When reading `async functions` like this one, it’s good practice to look for the `await` calls because they are all places where unknown other amounts of work might take place before the next line of code executes.

```swift
func processWeather() async {
    let records = await fetchWeatherHistory()
    // anything could happen here
    let average = await calculateAverageTemperature(for: records)
    // or here
    let response = await upload(result: average)
    // or here
    print("Server response: \(response)")
}
```

- We’re only using `local variables` inside this function, so they `are safe`. 

- However, if you were relying on `properties from a class`, for example, they `might have changed` between each of those `await` lines.

- Swift provides ways of protecting against this using a system known as `actors`.


## How to call async throwing functions

- Swift’s `async functions` can be `throwing` or `non-throwing` depending on how you want them to behave.

- Although we mark the function as being `async` `throws`, we call the function using `try` `await` the keyword order is flipped.

```swift
func fetchFavorites() async throws -> [Int] {
    let url = URL(string: "https://hws.dev/user-favorites.json")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Int].self, from: data)
}

if let favorites = try? await fetchFavorites() {
    print("Fetched \(favorites.count) favorites.")
} else {
    print("Failed to fetch favorites.")
}
```

- `fetchFavorites()` method attempts to download some JSON from the server, decode it into an array of integers, and return the result.

- Both `fetching data` and `decoding` it are throwing functions, so we need to use `try` in both those places.

- Those errors aren’t being handled in the function, so we need to mark `fetchFavorites()` as also being `throwing` so Swift can let any errors bubble up to whatever called it.

- Notice that the function is marked `async throws` but the function calls are marked `try await` so the keyword order gets reversed.

- So, it’s `“asynchronous, throwing”` in the function definition, but `“throwing, asynchronous”` at the call site. 

- Think of it as `unwinding a stack`.

- Not only does `try await` read more easily, but it’s also more reflective of what’s actually happening when our code executes.

- We’re waiting for some work to complete, and when it does complete we’ll check whether it ended up throwing an error or not.


## What calls the first async function?

- You can only call `async functions` from `other async functions`, because they `might need to suspend` themselves and everything that is waiting for them.

- If only `async functions` can call `other async functions`, what starts it all what calls the very first async function?

- Well, there are three main approaches you’ll find yourself using:

1- First, in simple command-line programs using the `@main attribute`, you can declare your `main()` method to be `async`. 

- This means your program will immediately launch into an `async function`, so you can call `other async functions` freely.

```swift
func processWeather() async {
    // Do async work here
}

@main
struct MainApp {
    static func main() async {
        await processWeather()
    }
}
```

2- Second, in apps built with something like `SwiftUI` the framework itself has various places that can trigger an `async function`. 

- For example, the `refreshable()` and `task()` modifiers can both call `async functions` freely.

- Using the `task()` modifier we could write a simple “View Source” app that fetches the content of a website when our view appears:

- Tip: Using `task()` will almost certainly `run our code away from the main thread`, but the `@State property wrapper` has specifically been `written to allow us to modify its value on any thread`.

```swift
struct ContentView: View {
    @State private var sourceCode = ""

    var body: some View {
        ScrollView {
            Text(sourceCode)
        }
        .task {
            await fetchSource()
        }
    }

    func fetchSource() async {
        do {
            let url = URL(string: "https://apple.com")!

            let (data, _) = try await URLSession.shared.data(from: url)
            sourceCode = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            sourceCode = "Failed to fetch apple.com"
        }
    }
}
```

3- The third option is that Swift provides a dedicated `Task API` that lets us `call async functions` from a `synchronous function`.

- When you use something like `Task` you’re asking Swift to `run some async code`.

- If you don’t care about the result you have nothing to wait for – the task will start running immediately while your own function continues, and it will always run to completion even if you don’t store the active task somewhere.

- This means you’re `not awaiting the result of the task`, so you `won’t run the risk of being suspended`.

- When you actually want to `use any returned value from your task`, that’s when `await` is required.

- This time we’re going to `trigger the network fetch` using a `button press`, which `is synchronous by default`, so we’re going to wrap our work in a `Task`.

- This is possible because we don’t need to wait for the task to complete – it will always run to completion as soon as it is made, and will take care of updating the UI for us.

```swift
struct ContentView: View {
    @State private var site = "https://"
    @State private var sourceCode = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Website address", text: $site)
                    .textFieldStyle(.roundedBorder)
                Button("Go") {
                    Task {
                        await fetchSource()
                    }
                }
            }
            .padding()

            ScrollView {
                Text(sourceCode)
            }
        }
    }

    func fetchSource() async {
        do {
            let url = URL(string: site)!
            let (data, _) = try await URLSession.shared.data(from: url)
            sourceCode = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            sourceCode = "Failed to fetch \(site)"
        }
    }
}
```


## What is the performance cost of calling an async function?

- Whenever we use `await` to call an `async function`, we mark a potential suspension point in our code – we’re acknowledging that it’s entirely possible our function will be suspended, along with all its callers, while the work completes.

- In terms of performance, this is not free: `synchronous` and `asynchronous` functions use a different calling convention internally, with the `asynchronous variant being slightly less efficient`.

- The important thing to understand here is that `Swift cannot tell at compile time` whether an `await call will suspend or not`, and so the same (slightly) `more expensive calling convention is used` regardless of what actually takes place at runtime.

- However, `what happens at runtime depends on whether the call suspends` or not:

1- If a `suspension happens`, then Swift will pause the function and all its callers, which has a small performance cost. 

- These will then be resumed later, and ultimately whatever performance cost you pay for the suspension is like a rounding error compared to the performance gain provided by `async/await` even existing.

2- If a `suspension does not happen`, no pause will take place and your function will continue to run with the same efficiency and timings as a synchronous function.

- That last part carries an important side effect: `using await will not cause your code to wait for one runloop to go by before continuing`.

- If your code doesn’t actually suspend, the only cost to calling an asynchronous function is the slightly more expensive calling convention, and if your code does suspend then any cost is more or less irrelevant because you’ve gained so much extra performance thanks to the suspension happening in the first place.


## How to create and use async properties

- Just as Swift’s functions can be `asynchronous`, `computed properties can also be asynchronous`, attempting to access them must also use `await` or similar, and may also need `throws` if errors can be thrown when computing the property.

- This is what allows things like the `value` property of `Task` to work, it’s a simple property, but we must access it using `await` because it might not have completed yet.

- `Important`: This is `only possible on read-only computed properties`, attempting to provide a setter will cause a compile error.

- To demonstrate this, we could create a `RemoteFile` struct that stores a `URL` and a `type that conforms to Decodable`. 

- This struct won’t actually fetch the URL when the struct is created, but will instead dynamically fetch the content’s of the URL every time the property is requested so that we can update our UI dynamically.

- Tip: If you use `URLSession.shared` to fetch your data it will `automatically be cached`, so we’re going to create a custom `URL session` that always ignores local and remote caches to make sure our remote file is always fetched.

```swift
// First, a URLSession instance that never uses caches
extension URLSession {
    static let noCacheSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
}

// Now our struct that will fetch and decode a URL every time we read its `contents` property
struct RemoteFile<T: Decodable> {
    let url: URL
    let type: T.Type

    var contents: T {
        get async throws {
            let (data, _) = try await URLSession.noCacheSession.data(from: url)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
}
```

- So, we’re fetching the URL’s contents every time `contents` is access, as opposed to storing the URL’s contents when a `RemoteFile` instance is created. 

- As a result, the property is marked both `async` and `throws` so that callers must use `await` or similar when accessing it.


## How to call an async function using async let

- Sometimes you want to run several `async operations` at the same time then wait for their results to come back, and the easiest way to do that is with `async let`.

- This lets you start several `async functions`, all of which begin running immediately, it’s `much more efficient than running them sequentially`.

- A common example of where this is useful is `when you have to make two or more network requests`, none of which relate to each other. 

- That is, if you need to get `Thing X` and `Thing Y` from a server, but `you don’t need to wait for X to return before you start fetching Y`.

- To demonstrate this, we could define a couple of structs to store data – `one to store a user’s account data`, and `one to store all the messages in their inbox`:

```swift
struct User: Decodable {
    let id: UUID
    let name: String
    let age: Int
}

struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}
```

- These two things can be fetched independently of each other, so rather than `fetching the user’s account details` then `fetching their message inbox` we want to `get them both together`.

- In this instance, rather than using a regular `await` call a better choice is `async let`, like this:

```swift
func loadData() async {
    
    async let (userData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-24601.json")!)
    async let (messageData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-messages.json")!)

    // more code to come
}
```

- That’s only a small amount of code, but there are three things I want to highlight in there:

1- Even though the `data(from:)` method is `async`, we don’t need to use `await` before it because that’s implied by `async let`.

2- The `data(from:)` method is also `throwing`, but we don’t need to use `try` to execute it because that gets pushed back to when we actually want to read its return value.

3- Both those network calls start immediately, but might complete in any order.

- Now we have two network requests in flight. 

- The next step is to wait for them to complete, decode their returned data into structs, and use that somehow.

- There are two things you need to remember:

1- Both our `data(from:)` calls might `throw`, so when we read those values we need to use `try`.

2- Both our `data(from:)` calls are `running concurrently` while our main `loadData()` function continues to execute, so we need to `read their values` using `await` in case they aren’t ready yet.

- So, we could complete our function by using `try await` for each of our network requests in turn, then print out the result:

```swift
func loadData() async {

    async let (userData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-24601.json")!)
    async let (messageData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-messages.json")!)

    do {
        let decoder = JSONDecoder()
        let user = try await decoder.decode(User.self, from: userData)
        let messages = try await decoder.decode([Message].self, from: messageData)
        print("User \(user.name) has \(messages.count) message(s).")
    } catch {
        print("Sorry, there was a network problem.")
    }
}

await loadData()
```

- The Swift compiler will automatically track which `async let` constants could `throw` errors and will enforce the use of `try` when reading their value.

- It doesn’t matter which form of `try` you use, so you can use `try`, `try?` or `try!` as appropriate.

- Tip: If you never try to read the value of a `throwing` `async let` call – i.e., if you’ve started the work but don’t care what it returns – then you don’t need to use `try` at all, which in turn means the function running the `async let` code might not need to handle errors at all.

- Although both our network requests are happening at the same time, we still need to wait for them to complete in some sort of order. 

- So, if you wanted to `update your user interface as soon as either user or messages arrived back` `async let` isn’t going to help by itself – you should look at the dedicated `Task` type instead.

- One complexity with `async let` is that `it captures any values it uses`, which means you might accidentally try to write code that isn’t safe. 

- Swift helps here by taking some steps to enforce that you aren’t trying to modify data unsafely.

- As an example, if we wanted to fetch the favorites for a user, we might have a function such as this one:

```swift
struct User: Decodable {
    let id: UUID
    let name: String
    let age: Int
}

struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

func fetchFavorites(for user: User) async -> [Int] {

    print("Fetching favorites for \(user.name)…")

    do {
        async let (favorites, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-favorites.json")!)
        return try await JSONDecoder().decode([Int].self, from: favorites)
    } catch {
        return []
    }
}

let user = User(id: UUID(), name: "Taylor Swift", age: 26)
async let favorites = fetchFavorites(for: user)
await print("Found \(favorites.count) favorites.")
```

- That function accepts a `User` parameter so it can print a status message.

- But what happens if our `User` was created as a `variable` and captured by `async let`? 

- You can see this for yourself if you change the user:

```swift
var user = User(id: UUID(), name: "Taylor Swift", age: 26)
```

- Even though `it’s a struct`, the `user variable will be captured` rather than copied and so Swift will `throw up` the build error `“Reference to captured var 'user' in concurrently-executing code.”`

- To fix this we need to make it clear the struct cannot change by surprise, even when captured, `by making it a constant` rather than a variable.


## What is the difference between await and async let?

- Swift lets us perform `async operations` using both `await` and `async let`, but although they both `run some async code` they don’t quite run the same.

- `await` immediately waits for the work to complete so we can read its result, whereas `async let` does not.

- If you want to make two network requests where one relates to the other, you might have code like this:

```swift
let first = await requestFirstData()
let second = await requestSecondData(using: first)
```

- There the call to `requestSecondData()` cannot start until the call to `requestFirstData()` has completed and returned its value it just doesn’t make sense for those two to run simultaneously.

- If you’re making several completely different requests – perhaps you want to download the latest news, the weather forecast, and check whether an app update was available – then `those things do not rely on each other to complete` and would be great candidates for `async let`:

```swift
func getAppData() -> ([News], [Weather], Bool) {
    async let news = getNews()
    async let weather = getWeather()
    async let hasUpdate = getAppUpdateAvailable()
    return await (news, weather, hasUpdate)
}
```

- Use `await` when it’s important you have a value before continuing.

- Use `async let` when your work can continue without the value for the time being, you can always use `await` later on when it’s actually needed.


## Why we can not call async functions using async var?

- Swift’s `async let` syntax provides short, helpful syntax `for running lots of work concurrently`, allowing us to wait for them all later on. 

- However, it only works as `async let` – it’s not possible to use `async var`.

- If you think about it, this restriction makes sense, consider pseudocode like this:

```swift
func fetchUsername() async -> String {
    // complex networking here
    "Taylor Swift"
}

async var username = fetchUsername()

username = "Justin Bieber"

print("Username is \(username)")
```

- That attempts to `create a variable asynchronously`, then writes to it directly. 

- Have we cancelled the async work? 
- If not, when the async work completes will it overwrite our new value? 
- Do we still need to use await when reading the value even after we’ve explicitly set it?

- This kind of code would create all sorts of confusion, so `it’s just not allowed` – `async let` is our only option.


## How to use continuations to convert completion handlers into async functions

- Older Swift code uses `completion handlers` for `notifying us when some work has completed`, and sooner or later you’re going to have to use it from an `async` function – either because you’re using a library someone else created, or because it’s one of your own functions but updating it to `async` would take a lot of work.

- Swift uses `continuations` to solve this problem, allowing us to `create a bridge between older functions with completion handlers and newer async` code.

- To demonstrate this problem, here’s some code that attempts to fetch some JSON from a web server, decode it into an array of `Message` structs, then send it back using a `completion handler`:

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

func fetchMessages(completion: @escaping ([Message]) -> Void) {
    let url = URL(string: "https://hws.dev/user-messages.json")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            if let messages = try? JSONDecoder().decode([Message].self, from: data) {
                completion(messages)
                return
            }
        }

        completion([])
    }.resume()
}
```

- Although the `dataTask(with:)` method does run our code on its own thread, this is `not an async function` in the sense of Swift’s `async/await` feature, which means it’s going to be messy to integrate into other code that does use modern `async` Swift.

- To fix this, Swift provides us with `continuations`, which `are special objects we pass into the completion handlers as captured values`. 

- Once the `completion handler fires`, we can either `return the finished value`, `throw an error`, or `send back a Result` that can be handled elsewhere.

- In the case of `fetchMessages()`, we want to write a `new async function` that calls the original, and `in its completion handler we’ll return whatever value was sent back`:

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

func fetchMessages(completion: @escaping ([Message]) -> Void) {
    let url = URL(string: "https://hws.dev/user-messages.json")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            if let messages = try? JSONDecoder().decode([Message].self, from: data) {
                completion(messages)
                return
            }
        }

        completion([])
    }.resume()
}

func fetchMessages() async -> [Message] {
    await withCheckedContinuation { continuation in
        fetchMessages { messages in
            continuation.resume(returning: messages)
        }
    }
}

let messages = await fetchMessages()

print("Downloaded \(messages.count) messages.")
```

- Starting a `continuation` is done using the `withCheckedContinuation()` function, which passes into itself the `continuation` we need to work with.

- It’s called a `“checked” continuation` because `Swift checks that we’re using the continuation correctly`, which means abiding by one very simple, very important rule:

- `Your continuation must be resumed exactly once. Not zero times, and not twice or more times – exactly once.`

- If you `call` the `checked continuation twice or more`, Swift will cause your `program to halt – it will just crash`. 

- If you `fail to resume the continuation` at all, Swift will `print out a large warning` in your debug log similar to this: `“SWIFT TASK CONTINUATION MISUSE: fetchMessages() leaked its continuation!”`

- This is because `you’re leaving the task suspended`, `causing any resources it’s using to be held indefinitely`.

- However, if you have checked your code carefully and you’re sure it is correct, you can if you want replace the `withCheckedContinuation()` function with a call to `withUnsafeContinuation()`, which `works exactly the same` way but `doesn’t add the runtime cost of checking you’ve used the continuation correctly`.


## How to create continuations that can throw errors

- Swift provides `withCheckedContinuation()` and `withUnsafeContinuation()` to let us `create continuations that can’t throw errors`. 

- If the API you’re using `can throw errors` you should use their throwing equivalents: `withCheckedThrowingContinuation()` and `withUnsafeThrowingContinuation()`.

- Both of these replacement functions work identically to their non-throwing counterparts, except `now you need to catch any errors thrown inside the continuation`.

- So, first we’d define the errors we want to throw, then we’d write a newer `async` version of `fetchMessages()` using `withCheckedThrowingContinuation()`, and handling the “no messages” error using whatever code we wanted:

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

func fetchMessages(completion: @escaping ([Message]) -> Void) {
    let url = URL(string: "https://hws.dev/user-messages.json")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            if let messages = try? JSONDecoder().decode([Message].self, from: data) {
                completion(messages)
                return
            }
        }

        completion([])
    }.resume()
}

// An example error we can throw
enum FetchError: Error {
    case noMessages
}

func fetchMessages() async -> [Message] {
    do {
        return try await withCheckedThrowingContinuation { continuation in
            fetchMessages { messages in
                if messages.isEmpty {
                    continuation.resume(throwing: FetchError.noMessages)
                } else {
                    continuation.resume(returning: messages)
                }
            }
        }
    } catch {
        return [
            Message(id: 1, from: "Tom", message: "Welcome to MySpace! I'm your new friend.")
        ]
    }
}

let messages = await fetchMessages()
print("Downloaded \(messages.count) messages.")
```

- That detects a lack of messages and sends back a welcome message instead, but you could also `let the error propagate upwards` by `removing do/catch` and making the new `fetchMessages()` function `throwing`.

- Tip: Using `withUnsafeThrowingContinuation()` comes with all the same warnings as using `withUnsafeContinuation()` – you should `only switch over to it if it’s causing a performance problem`.


## How to store continuations to be resumed later

- Many of Apple’s frameworks report back success or failure using multiple different delegate callback methods rather than completion handlers, which means a simple continuation won’t work.

- As a simple example, if you were implementing `WKNavigationDelegate` to handle navigating around a `WKWebView` you would implement methods like this:

```swift
func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    // our work succeeded
}

func webView(WKWebView, didFail: WKNavigation!, withError: Error) {
    // our work failed
}
```

- Rather than receiving the result of our work through a single completion closure, we instead get the result in two different places.

- In this situation we need to do a little more work to create `async functions` using `continuations`, because `we need to be able to resume the continuation` in either method.

- To solve this problem you need to know that `continuations are just structs with a specific generic type`.

- For example, a `checked continuation that succeeds with a string and never throws an error` has the type `CheckedContinuation<String, Never>`, and an `unchecked continuation that returns an integer array and can throw errors` has the type `UnsafeContinuation<[Int], Error>`.

- All this is important because to solve our delegate callback problem `we need to stash away a continuation in one method` – when we trigger some functionality – then `resume it from different methods` based on `whether our code succeeds or fails`.

- So we’re going to create an `ObservableObject` to wrap `Core Location`, making it `easier to request the user’s location`.

- First, add these imports to your code so `we can read their location`, and also `use SwiftUI’s LocationButton to get standardized UI`:

```swift
import CoreLocation
import CoreLocationUI
```

- Second, we’re going to create a small part of a `LocationManager` class that has two properties:

1- one for `storing a continuation to track whether we have their location coordinate or an error`.

2- one to `track an instance of CLLocationManager that does the work of finding the user`. 

- This also needs a small initializer so the `CLLocationManager` knows to report location updates to us.

```swift
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Error>?
    let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    // More code to come
}
```

- Because that observable object is used with SwiftUI, I’ve marked it with the `@MainActor attribute` to `avoid updating the user interface on a background thread`.

- Third, we need to `add an async function` that requests the user’s location. 

- This needs to be wrapped inside a `withCheckedThrowingContinuation()` call, so that `Swift creates a continuation we can stash away and use later`.

```swift
func requestLocation() async throws -> CLLocationCoordinate2D? {
    try await withCheckedThrowingContinuation { continuation in
        locationContinuation = continuation
        manager.requestLocation()
    }
}
```

- And finally we need to implement the two methods that might be called after we request the user’s location: `didUpdateLocations` will be `called if their location was received`, and `didFailWithError otherwise`.

- `Both of these need to resume our continuation`, with `the former sending back the first location coordinate we were given`, and `the latter throwing whatever error occurred`:

```swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationContinuation?.resume(returning: locations.first?.coordinate)
}

func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationContinuation?.resume(throwing: error)
}
```

- So, `by storing our continuation as a property we’re able to resume it in two different places` – `once where things go to plan`, and `once where things go wrong` for whatever reason.

- Either way, `no matter what happens our continuation resumes exactly once`.

- At this point our `continuation wrapper is complete`, so we can use it inside a SwiftUI view. 

- If we put everything together, here’s the end result:

```swift
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Error>?
    let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() async throws -> CLLocationCoordinate2D? {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.first?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        LocationButton {
            Task {
                if let location = try? await locationManager.requestLocation() {
                    print("Location: \(location)")
                } else {
                    print("Location unknown.")
                }
            }
        }
        .frame(height: 44)
        .foregroundColor(.white)
        .clipShape(Capsule())
        .padding()
    }
}
```


## How to fix the error “async call in a function that does not support concurrency”

- This error occurs when you’ve `tried to call an async function from a synchronous function`, which is not allowed in Swift.

- `Asynchronous functions` must be able to suspend themselves and their callers, and `synchronous functions` simply don’t know how to do that.

- If your `asynchronous work needs to be waited` for, you don’t have much of a choice but to `mark your current code as also being async so that you can use await as normal`.

- However, sometimes this can result in a bit of an `“async infection”` – you mark `one function as being async`, which `means its caller needs to be async too`, `as does its caller, and so on`, until you’ve turned one error into 50.

- In this situation, you can create a dedicated `Task` to solve the problem.

```swift
func doAsyncWork() async {
    print("Doing async work")
}

func doRegularWork() {
    Task {
        await doAsyncWork()
    }
}

doRegularWork()
```

- `Tasks` like this one are `created and run immediately`. 

- We `aren’t waiting for the task to complete`, so we `shouldn’t use await when creating it`.


## What is the difference between Sequence AsyncSequence and AsyncStream?

- Swift provides `several ways of receiving a potentially endless flow of data`, allowing us to `read values one by one`, or `loop over them` using `for`, `while`, or similar.

- The simplest is the `Sequence protocol`, which continually returns values until the sequence is terminated by returning `nil`.

- Lots of things conform to `Sequence`, including `arrays, strings, ranges, Data` and more.

- Through protocol extensions `Sequence` also gives us access to a variety of methods, including `contains()`, `filter()`, `map()`, and others.

- The `AsyncSequence protocol` is almost identical to `Sequence`, with the important exception that `each element in the sequence is returned asynchronously`.

- It actually has two major impacts on the way they work.

1- Reading a value from the `async sequence` must use `await` so the `sequence can suspend itself` while reading its next value. This might be performing some complex work, or perhaps fetching data from a server.

2- More advanced `async sequences` known as `async streams` might `generate values faster than you can read them`, in which case you can `either discard the extra values or buffer them to be read later on`.

- In the first case think of it like `your code wanting values faster than the async sequence can make them`. 

- In the second case it’s more like `the async sequence generating data faster than than your code can read them`.

- Otherwise, `Sequence` and `AsyncSequence` have lots in common: 

- The `code to create a custom one yourself is almost the same`, `both can throw errors if you want`, `both get access to common functionality` such as `map()`, `filter()`, `contains()`, and `reduce()`, and you can also use `break` or `continue` to exit loops over either of them.


## How to loop over an AsyncSequence using for await

- You can loop over an `AsyncSequence` using Swift’s regular loop types, `for`, `while`, and `repeat`.

- Whenever you `read a value from the async sequence` you must use either `await` or `try await` depending on whether it can throw errors or not.

- As an example, `URL` has a built-in `lines` property that generates an `async sequence` of all the lines directly from a URL. 

- This does a lot of work internally: making the network request, fetching part of the data, converting it into a string, sending it back for us to use, then repeating fetch, convert, and send again and again until the server stops sending back data.

```swift
func fetchUsers() async throws {
    let url = URL(string: "https://hws.dev/users.csv")!

    for try await line in url.lines {
        print("Received user: \(line)")
    }
}

try? await fetchUsers()
```

- Notice how we must use `try along with await`, because `fetching data from the network might throw errors`.

- Using `lines` returns a specialized type called `AsyncLineSequence`, which returns individual lines from the download as strings. 

- Because our source happens to be a `comma-separated values file (CSV)`, we can write code to read the values from each line easily enough:

```swift
func printUsers() async throws {
    let url = URL(string: "https://hws.dev/users.csv")!

    for try await line in url.lines {
        let parts = line.split(separator: ",")
        guard parts.count == 4 else { continue }

        guard let id = Int(parts[0]) else { continue }
        let firstName = parts[1]
        let lastName = parts[2]
        let country = parts[3]

        print("Found user #\(id): \(firstName) \(lastName) from \(country)")
    }
}

try? await printUsers()
```

- Just like a `regular sequence`, using an `async sequence` in this way effectively generates an `iterator` then calls `next()` on it repeatedly until it `returns nil`, at which point the loop finishes.

- If you want more control over how the sequence is read, you can of course `create your own iterator` then call `next()` whenever you want and as often as you want. 

- Again, it will send back `nil` when the `sequence is empty`, at which point you should `stop calling it`.

- For example, we could `read the first user from our CSV and treat them specially`, `then read the next four users and do something specific for them`, `then finally reduce all the remainder down into an array of other users`:

```swift
func printUsers() async throws {
    let url = URL(string: "https://hws.dev/users.csv")!

    var iterator = url.lines.makeAsyncIterator()

    if let line = try await iterator.next() {
        print("The first user is \(line)")
    }

    for i in 2...5 {
        if let line = try await iterator.next() {
            print("User #\(i): \(line)")
        }
    }

    var remainingResults = [String]()

    while let result = try await iterator.next() {
        remainingResults.append(result)
    }

    print("There were \(remainingResults.count) other users.")
}

try? await printUsers()
```


## How to manipulate an AsyncSequence using map() filter() and more

- `AsyncSequence` has implementations of many of the same methods that come with `Sequence`, but how they operate varies.

- Some return a single value that fulfills your request, such as `requesting the first value from the async sequence`. 

- Others return a `new kind of async sequence`, such as filtering values as they arrive.

- This distinction in turn `affects how they are called`: 

- `returning a single value` requires you to `await at the call site`.

- `returning a new async sequence` requires you to `await later on when you’re reading values from the new sequence`.

- `Mapping an async sequence` creates a new async sequence with the type `AsyncMapSequence`, which stores both your `original async sequence` and also `the transformation function you want to use`.

- You effectively put the transformation into a chain of work: 

- `The sequence now fetches an item, transforms it, then sends it back`.

- We could map over the lines from a `URL` to make each line uppercase, like this:

```swift
func shoutQuotes() async throws {
    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let uppercaseLines = url.lines.map(\.localizedUppercase)

    for try await line in uppercaseLines {
        print(line)
    }
}

try? await shoutQuotes()
```

- This also works for converting between types using `map()`, like this:

```swift
struct Quote {
    let text: String
}

func printQuotes() async throws {
    let url = URL(string: "https://hws.dev/quotes.txt")!

    let quotes = url.lines.map(Quote.init)

    for try await quote in quotes {
        print(quote.text)
    }
}

try? await printQuotes()
```

- Alternatively, we could use `filter()` to check every line with a predicate, and process only those that pass. 

- Using our quotes, we could print only anonymous quotes like this:

```swift
func printAnonymousQuotes() async throws {

    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }

    for try await line in anonymousQuotes {
        print(line)
    }
}

try? await printAnonymousQuotes()
```

- Or we could use `prefix()` to read just the first five values from an async sequence:

```swift
func printTopQuotes() async throws {

    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let topQuotes = url.lines.prefix(5)

    for try await line in topQuotes {
        print(line)
    }
}

try? await printTopQuotes()
```

- And of course you can also combine these together in varying ways depending on what result you want. 

- For example, this will filter for anonymous quotes, pick out the first five, then make them uppercase:

```swift
func printQuotes() async throws {

    let url = URL(string: "https://hws.dev/quotes.txt")!

    let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
    let topAnonymousQuotes = anonymousQuotes.prefix(5)
    let shoutingTopAnonymousQuotes = topAnonymousQuotes.map(\.localizedUppercase)

    for try await line in shoutingTopAnonymousQuotes {
        print(line)
    }
}

try? await printQuotes()
```

- Just like using a regular `Sequence`, `the order you apply these transformations matters` – putting `prefix()` before `filter()` will pick out the first five quotes then select only the ones that are anonymous, which might produce fewer results.

- Each of these transformation methods `returns a new type specific to what the method does`, so calling `map()` returns an `AsyncMapSequence`, calling `filter()` returns an `AsyncFilterSequence`, and calling `prefix()` returns an `AsyncPrefixSequence`.

- When you stack multiple transformations together – for example, `a filter, then a prefix, then a map`– this will inevitably produce a fairly `complex return type`, so if you intend to send back one of the complex async sequences you should consider an opaque return type like this:

```swift
func getQuotes() async -> some AsyncSequence {

    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
    
    let topAnonymousQuotes = anonymousQuotes.prefix(5)
    
    let shoutingTopAnonymousQuotes = topAnonymousQuotes.map(\.localizedUppercase)
    
    return shoutingTopAnonymousQuotes
}

let result = await getQuotes()

do {
    for try await quote in result {
        print(quote)
    }
} catch {
    print("Error fetching quotes")
}
```

- All the transformations so far have created `new async sequences` and so we `did not needed to use them with await`, but many also produce a single value. 

- These must use `await` in order to `suspend until all parts of the sequence have been returned`, and may also need to use `try` if the `sequence is throwing`.

- For example, `allSatisfy()` will check whether `all elements in an async sequence pass a predicate of your choosing`:

```swift
func checkQuotes() async throws {
    
    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let noShortQuotes = try await url.lines.allSatisfy { $0.count > 30 }
    
    print(noShortQuotes)
}

try? await checkQuotes()
```

- Important: As with regular sequences, in order to return a correct value `allSatisfy()` must have fetched every value in the sequence first, and therefore `using it with an infinite sequence will never return a value`. 

- The same is true of other similar functions, such as `min()`, `max()`, and `reduce()`, so be careful.

- You can of course `combine methods that create new async sequences and return a single value`, for example to fetch lots of random numbers, convert them to integers, then find the largest:

```swift
func printHighestNumber() async throws {

    let url = URL(string: "https://hws.dev/random-numbers.txt")!

    if let highest = try await url.lines.compactMap(Int.init).max() {
        print("Highest number: \(highest)")
    } else {
        print("No number was the highest.")
    }
}

try? await printHighestNumber()
```

- Or to sum all the numbers:

```swift
func sumRandomNumbers() async throws {

    let url = URL(string: "https://hws.dev/random-numbers.txt")!
    
    let sum = try await url.lines.compactMap(Int.init).reduce(0, +)
    
    print("Sum of numbers: \(sum)")
}

try? await sumRandomNumbers()
```
