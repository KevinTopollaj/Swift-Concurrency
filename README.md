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
* [What’s the performance cost of calling an async function?](#What’s-the-performance-cost-of-calling-an-async-function)
* [How to create and use async properties](#How-to-create-and-use-async-properties)
* [How to call an async function using async let](#How-to-call-an-async-function-using-async-let)
* [What is the difference between await and async let?](#What-is-the-difference-between-await-and-async-let)


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


## What’s the performance cost of calling an async function?

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

