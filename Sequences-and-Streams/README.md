# Sequences and streams

## Table of contents

* [What is the difference between Sequence AsyncSequence and AsyncStream?](#What-is-the-difference-between-Sequence-AsyncSequence-and-AsyncStream)
* [How to loop over an AsyncSequence using for await](#How-to-loop-over-an-AsyncSequence-using-for-await)
* [How to manipulate an AsyncSequence using map() filter() and more](#How-to-manipulate-an-AsyncSequence-using-map()-filter()-and-more)
* [How to create a custom AsyncSequence](#How-to-create-a-custom-AsyncSequence)
* [How to convert an AsyncSequence into a Sequence](#How-to-convert-an-AsyncSequence-into-a-Sequence)



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


## How to create a custom AsyncSequence

- There are only three differences between creating an `AsyncSequence` and creating a regular `Sequence`:

1- We need to conform to the `AsyncSequence` and `AsyncIteratorProtocol` protocols.

2- The `next()` method of our `iterator` must be marked `async`.

3- We need to create a `makeAsyncIterator()` method rather than `makeIterator()`.


- That last point technically allows us to create one type that is both a synchronous and asynchronous sequence, although I’m not sure when that would be a good idea.

- First, the simple one, which is an `async sequence` that doubles numbers every time `next()` is called:

```swift
struct DoubleGenerator: AsyncSequence, AsyncIteratorProtocol {
    
    typealias Element = Int
    
    var current = 1

    mutating func next() async -> Element? {
        defer { current &*= 2 }

        if current < 0 {
            return nil
        } else {
            return current
        }
    }

    func makeAsyncIterator() -> DoubleGenerator {
        self
    }
}

let sequence = DoubleGenerator()

for await number in sequence {
    print(number)
}
```

- Tip: In case you haven’t seen it before, `&*=` multiples with overflow, meaning that `rather than running out of room when the value goes beyond the highest number of a 64-bit integer, it will instead flip around to be negative`. 

- We use this to our advantage, returning `nil` when we reach that point.

- If you prefer having a separate iterator struct, that also works as with `Sequence` and you don’t need to adjust the calling code:

```swift
struct DoubleGenerator: AsyncSequence {
    typealias Element = Int

    struct AsyncIterator: AsyncIteratorProtocol {
        var current = 1

        mutating func next() async -> Element? {
            defer { current &*= 2 }

            if current < 0 {
                return nil
            } else {
                return current
            }
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}

let sequence = DoubleGenerator()

for await number in sequence {
    print(number)
}
```

- Now let’s look at a more complex example, which will periodically fetch a URL that’s either local or remote, and send back any values that have changed from the previous request.

- This is more complex for various reasons:

1- Our `next()` method will be marked `throws`, so callers are responsible for handling loop errors.

2- Between checks we’re going to sleep for some number of seconds, so we don’t overload the network. This will be configurable when creating the watcher, but internally it will use `Task.sleep()`.

3- If we get data back and it hasn’t changed, we go around our loop again – wait for some number of seconds, re-fetch the URL, then check again.

4- Otherwise, if there has been a change between the old and new data, we `overwrite our old data with the new data and send it back`.

5- If no data is returned from our request, we immediately terminate the `iterator` by sending back `nil`.

6- This is important: once our `iterator ends`, any further attempt to call `next()` must also return `nil`. This is part of the design of `AsyncSequence`, so stick to it.

- To add to the complexity a little, `Task.sleep()` `measures its time in nanoseconds`, so `to sleep for one second you should specify 1 billion as the sleep amount`.

- It’s also particularly powerful when combined with `SwiftUI’s task()` modifier, because the `network fetches will automatically start when a view is shown and cancelled when it disappears`. 

- This allows you to constantly watch for new data coming in, and stream it directly into your UI.

- Creating a `URLWatcher` struct that conforms to the `AsyncSequence` protocol, along with an example of it being used to display a list of users in a SwiftUI view:

```swift
struct URLWatcher: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Data

    let url: URL
    let delay: Int
    private var comparisonData: Data?
    private var isActive = true

    init(url: URL, delay: Int = 10) {
        self.url = url
        self.delay = delay
    }

    mutating func next() async throws -> Element? {
        // Once we're inactive always return nil immediately
        guard isActive else { return nil }

        if comparisonData == nil {
            // If this is our first iteration, return the initial value
            comparisonData = try await fetchData()
        } else {
            // Otherwise, sleep for a while and see if our data changed
            while true {
                try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
                let latestData = try await fetchData()

                if latestData != comparisonData {
                    // New data is different from previous data,
                    // so update previous data and send it back
                    comparisonData = latestData
                    break
                }
            }
        }

        if comparisonData == nil {
            isActive = false
            return nil
        } else {
            return comparisonData
        }
    }

    private func fetchData() async throws -> Element {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    func makeAsyncIterator() -> URLWatcher {
        self
    }
}

// As an example of URLWatcher in action, try something like this:
struct User: Identifiable, Decodable {
    let id: Int
    let name: String
}

struct ContentView: View {
    @State private var users = [User]()

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .task {
            // continuously check the URL watcher for data
            await fetchUsers()
        }
    }

    func fetchUsers() async {
        let url = URL(fileURLWithPath: "FILENAMEHERE.json")
        let urlWatcher = URLWatcher(url: url, delay: 3)

        do {
            for try await data in urlWatcher {
                try withAnimation {
                    users = try JSONDecoder().decode([User].self, from: data)
                }
            }
        } catch {
            // just bail out
        }
    }
}
```

- To make that work in your own project, replace “FILENAMEHERE” with the location of a local file you can test with. 

- For example, I might use /Users/twostraws/users.json, giving that file the following example contents:

```swift
[
    {
        "id": 1,
        "name": "Paul"
    }
]
```

- When the code first runs the list will show Paul, but if you edit the JSON file and re-save with extra users, they will just slide into the SwiftUI list automatically.


## How to convert an AsyncSequence into a Sequence

- Swift does not provide a built-in way of converting an `AsyncSequence` into a regular `Sequence`, but often you’ll want to make this conversion yourself so you `don’t need to keep awaiting results to come back in the future`.

- The easiest thing to do is call `reduce(into:)` on the sequence, appending each item to an array of the sequence’s element type. 

- To make this more reusable, I’d recommend adding an extension such as this one:

```swift
extension AsyncSequence {

    func collect() async rethrows -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
    
}
```

- With that in place, you can now call `collect()` on any `async sequence` in order to `get a simple array of its values`. 

- Because this is an `async operation`, you must call it using `await` like so:


```swift
extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

func getNumberArray() async throws -> [Int] {
    let url = URL(string: "https://hws.dev/random-numbers.txt")!
    let numbers = url.lines.compactMap(Int.init)
    return try await numbers.collect()
}

if let numbers = try? await getNumberArray() {
    for number in numbers {
        print(number)
    }
}
```

- Tip: Because we’ve made `collect()` use `rethrows`, you only need to call it using `try` if the call to `reduce()` would normally throw, so if you have an `async sequence` that doesn’t throw errors you can skip try entirely.
