# Actors

## Table of contents

* [What is an actor and why does Swift have them?](#What-is-an-actor-and-why-does-Swift-have-them)
* [How to create and use an actor in Swift](#How-to-create-and-use-an-actor-in-Swift)
* [How to make function parameters isolated](#How-to-make-function-parameters-isolated)
* [How to make parts of an actor nonisolated](#How-to-make-parts-of-an-actor-nonisolated)
* [How to use MainActor to run code on the main queue](#How-to-use-MainActor-to-run-code-on-the-main-queue)
* [Understanding how global actor inference works](#Understanding-how-global-actor-inference-works)
* [What is actor hopping and how can it cause problems?](#What-is-actor-hopping-and-how-can-it-cause-problems)
* [What is the difference between actors classes and structs?](#What-is-the-difference-between-actors-classes-and-structs)
* [Do not use an actor for your SwiftUI data models](#Do-not-use-an-actor-for-your-SwiftUI-data-models)
* [How to download JSON from the internet and decode it into any Codable type](#How-to-download-JSON-from-the-internet-and-decode-it-into-any-Codable-type)



## What is an actor and why does Swift have them?

- Swift’s `actors are conceptually like classes that are safe to use in concurrent environments`.

- This safety is made possible because `Swift automatically ensures no two pieces of code attempt to access an actor’s data at the same time` – it is made impossible by the compiler, rather than requiring developers to write boilerplate code using systems such as locks.

- In the following chapters we’re going to explore more about how actors work and when you should use them, but here is the least you need to know:

1- Actors are created using the `actor` keyword. This `is a concrete nominal type in Swift`, like structs, classes, and enums.

2- Like classes, `actors are reference types`. This `makes them useful for sharing state in your program`.

3- They have many of the same features as classes: you can give them properties, methods (async or otherwise), initializers, and subscripts, they can conform to protocols, and they can be generic.

4- Actors `do not support inheritance`, so they `cannot have convenience initializers`, and do `not support either final or override`.

5- All actors automatically conform to the `Actor` protocol, which `no other type can use`. This allows you to `write code restricted to work only with actors`.

- There is one more behavior of `actors` that lies at the center of their existence: `if you’re attempting to read a variable property or call a method on an actor, and you’re doing it from outside the actor itself, you must do so asynchronously using await`.

```swift
actor User {
    var score = 10

    func printScore() {
        print("My score is \(score)")
    }

    func copyScore(from other: User) async {
        score = await other.score
    }
}

let actor1 = User()
let actor2 = User()

await print(actor1.score)
await actor1.copyScore(from: actor2)
```

- You can see several things in action there:

1- The new `User` type is created using the `actor` keyword.

2- It can have properties and methods just like structs or classes.

3- The `printScore()` method can access the local `score` property just fine, because it’s our actor’s method reading its own property.

4- But in `copyScore(from:)` we’re attempting to read the `score from another user`, and we can’t read their `score` property without marking the request with `await`.

5- Code from outside the `actor` also needs to use `await`.

- The reason the `await` call is needed in `copyScore(from:)` is central to the reasons actors are needed at all.

- You see, `rather than just letting us poke around in an actor’s mutable state`, Swift silently translates that request into what is effectively a message that goes into the actor’s message inbox: “please let me know your score as soon as you can.”

- If the actor is currently idle it can respond with the score straight away and our code continues no different from if we had used a class or a struct.

- But the `actor might also have multiple other messages waiting in its inbox that it needs to deal with first`, so our score request has to `wait`.

- Eventually our request makes it to the top of the inbox and it will be dealt with, and the `copyScore(from:)` method will continue.

- This means several things:

1- `Actors are effectively operating a private serial queue for their message inbox`, taking requests one at a time and fulfilling them. This executes requests in the order they were received, but `you can also use task priority to escalate requests`.

2- Only `one piece of code at a time can access an actor’s mutable state` unless you specifically mark some things as being `unprotected`. Swift calls this `actor isolation`.

3- Just like regular `await` calls, `reading an actor’s property or method marks a potential suspension point` – we might get a value back immediately, but it might also take a little time.

4- Any `state that is not mutable` – i.e., `a constant property` – can be accessed without `await`, because it’s always going to be safe.

-  If you are writing code inside an actor’s method, you can read other properties on that actor and call its synchronous methods without using `await`, but if you’re trying to use that data from outside the actor `await` is required even for synchronous properties and methods.

- Think of situations where using `self` is possible: if you could `self` you don’t need `await`.

- `Writing properties from outside an actor is not allowed, with or without await.`

- If you ever need to make sure that access to some object is restricted to a single task at a time, actors are perfect.

- This is more common than you might think – yes, `UI work should be restricted to the main thread`, but `you probably also want to restrict database access so that you can’t write conflicting data`, for example.

- There are also times when `simultaneous concurrent access to data can cause data races` – when the outcome of your work depends on the order in which tasks complete.

- These errors are particularly nasty to find and fix, but with actors such data races become impossible.

- `Tip`: Creating an instance of `an actor has no extra performance cost` compared to creating an instance of a class; `the only performance difference comes when trying to access the protected state of an actor, which might trigger task suspension`.


## How to create and use an actor in Swift

- Creating and using an `actor` in Swift takes two steps: create the type using `actor`, then use `await` when accessing its properties or methods externally.

- Swift takes care of everything else for us, including ensuring that properties and methods must be accessed safely.

- Let’s look at a simple example: a URL cache that remembers the data for each URL it downloads. 

- Here’s how that would be created and used:

```swift
actor URLCache {
    private var cache = [URL: Data]()

    func data(for url: URL) async throws -> Data {
        if let cached = cache[url] {
            return cached
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        cache[url] = data
        return data
    }
}

@main
struct App {
    static func main() async throws {
        let cache = URLCache()

        let url = URL(string: "https://apple.com")!
        let apple = try await cache.data(for: url)
        let dataString = String(decoding: apple, as: UTF8.self)
        print(dataString)
    }
}
```

- I marked its internal `cache` dictionary as `private`, so the only way we can access cached data is using the `data(for:)` method.

- This provides some degree of safety, because we might do some sort of special work inside the method that would be bypassed by accessing the property directly.

- However, the `real protection here is that the property and method are both encapsulated inside an actor`, which `means only a single thread can use them at any given time`.

- In practice, this avoids two problems:

1- Attempting to read from a dictionary at the same time we’re writing to it, which can cause your app to crash.

2- Two or more simultaneous requests for the same uncached URL coming in, forcing our code to fetch and store the same data repeatedly. This is a data race: whether we make two requests or one depends on the exact way our code is executed.

- However, this ease of use does come with some extra responsibility: 

- It’s really important you keep in mind the `serial queue behavior of actors`, because it’s entirely possible you can create massive speed bumps in your code just because you wrote `actor` rather than `class`.

- Think about the URL cache we just made, for example – just by using `actor` rather than `class` when we made it, `we forced it to load only a single URL at a time`.

-  If that’s what you want then you’re all set, but if not then you’ll be wondering why all its requests are handled one by one.

- The best example of why data races are problematic – the one that is often taught in computer science degrees – is about bank accounts, because here data races can result in serious real-world problems.

- To see why, here’s an example `BankAccount class` that handles sending and receiving money:

```swift
class BankAccount {
    var balance: Decimal

    init(initialBalance: Decimal) {
        balance = initialBalance
    }

    func deposit(amount: Decimal) {
        balance = balance + amount
    }

    func transfer(amount: Decimal, to other: BankAccount) {
        // Check that we have enough money to pay
        guard balance > amount else { return }

        // Subtract it from our balance
        balance = balance - amount

        // Send it to the other account
        other.deposit(amount: amount)
    }
}

let firstAccount = BankAccount(initialBalance: 500)
let secondAccount = BankAccount(initialBalance: 0)
firstAccount.transfer(amount: 500, to: secondAccount)
```

- That’s a `class`, so Swift `won’t do anything to stop us from accessing the same piece of data multiple times`.

- In the worst case two parallel calls to `transfer()` would be called on the same `BankAccount` instance, and the following would occur:

1- The first would check whether the balance was sufficient for the transfer. It is, so the code would continue.

2- The second would also check whether the balance was sufficient for the transfer. It still is, so the code would continue.

3- The first would then subtract the amount from the balance, and deposit it in the other account.

4- The second would then subtract the amount from the balance, and deposit it in the other account.

- Well, what happens if the account we’re transferring from contains $100, and we’re asked to transfer $80 to the other account? 

- If we follow the steps above, both calls to `transfer()` will happen in parallel and see that there was enough for the transfer to take place, then both will transfer the money across.

- The end result is that our check for sufficient funds wasn’t useful, and one account ends up with -$60 – something that might incur fees, or perhaps not even be allowed depending on the type of account they have.

- If we switch this type to be an `actor`, that problem goes away. 

- This means using `actor BankAccount` rather than `class BankAccount`, but also using `async and await` because we can’t directly call `deposit()` on the other bank account and instead need to post the request as a message to be executed later.

```swift
actor BankAccount {
    var balance: Decimal

    init(initialBalance: Decimal) {
        balance = initialBalance
    }

    func deposit(amount: Decimal) {
        balance = balance + amount
    }

    func transfer(amount: Decimal, to other: BankAccount) async {
        // Check that we have enough money to pay
        guard balance > amount else { return }

        // Subtract it from our balance
        balance = balance - amount

        // Send it to the other account
        await other.deposit(amount: amount)
    }
}

let firstAccount = BankAccount(initialBalance: 500)
let secondAccount = BankAccount(initialBalance: 0)
await firstAccount.transfer(amount: 500, to: secondAccount)
```

- With that change, our bank accounts can no longer fall into negative values by accident, which avoids a potentially nasty result.

- In other places, actors can prevent bizarre results that ought to be impossible.

- For example, what would happen if our example was a basketball team rather than a bank account, and we were transferring players rather than money? 

- Without actors we could end up in the situation where we transfer the same player twice – Team A would end up without them, and Team B would have them twice!


## How to make function parameters isolated

- Any `properties and methods that belong to an actor are isolated to that actor`. 

- You can `make external functions isolated to an actor if you want`.

- This `allows the function to access actor-isolated state as if it were inside that actor`, without needing to use `await`.

- Here’s a simple example so you can see what I mean:

```swift
actor DataStore {
    var username = "Anonymous"
    var friends = [String]()
    var highScores = [Int]()
    var favorites = Set<Int>()

    init() {
        // load data here
    }

    func save() {
        // save data here
    }
}

func debugLog(dataStore: isolated DataStore) {
    print("Username: \(dataStore.username)")
    print("Friends: \(dataStore.friends)")
    print("High scores: \(dataStore.highScores)")
    print("Favorites: \(dataStore.favorites)")
}

let data = DataStore()
await debugLog(dataStore: data)
```

- That creates a `DataStore` actor with various properties plus a couple of placeholder methods, then creates a `debugLog()` method that prints those without using `await` – they can be accessed directly.

- Notice the addition of the `isolated` keyword in the function signature, that’s what allows this direct access, and `it even allows the function to write to those properties too`.

- Using `isolated` like this `does not bypass any of the underlying safety or implementation of actors` – there can still only be one thread accessing the actor at any one time.

- What we’ve done `just pushes that access out by a level`, because `now the whole function must be run on that actor rather than just individual lines inside it`.

- In practice, this means `debugLog(dataStore:)` needs to be called using `await`.

- This approach has an important side effect: `because the whole function is now isolated to the actor`, it `must be called using await` even though it isn’t marked as `async`.

- This `makes the function itself a single potential suspension point` rather `than individual accesses to the actor being suspension points`.

- In case you were wondering, `you can’t have two isolation parameters`, because it wouldn’t really make sense – which one is executing the function?


## How to make parts of an actor nonisolated

- All `methods and mutable properties inside an actor are isolated to that actor by default`, which means `they cannot be accessed directly from code that’s external to the actor`.

- `Access to constant properties is automatically allowed` because they are inherently safe from race conditions, but if you want you can make some methods excepted by using the `nonisolated` keyword.

- Actor methods that are non-isolated can access other non-isolated state, such as constant properties or other methods that are marked non-isolated.

- However, `they cannot directly access isolated state like an isolated actor method would`, they need to use `await` instead.

- To demonstrate non-isolated methods, we could write a User actor that has three properties: two constant strings for their username and password, and a variable Boolean to track whether they are online.

- Because `password is constant`, `we could write a non-isolated method that returns the hash of that password using CryptoKit`, like this:

```swift
import CryptoKit
import Foundation

actor User {
    let username: String
    let password: String
    var isOnline = false

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    nonisolated func passwordHash() -> String {
        let passwordData = Data(password.utf8)
        let hash = SHA256.hash(data: passwordData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

let user = User(username: "twostraws", password: "s3kr1t")
print(user.passwordHash())
```

- I’d like to pick out a handful of things in that code:

1. Marking `passwordHash()` as `nonisolated` means that we can call it externally without using `await`.

2. We can also use `nonisolated` with computed properties, which in the previous example would have made `nonisolated var passwordHash: String`. Stored properties may not be non-isolated.

3. Non-isolated properties and methods can access only other non-isolated properties and methods, which in our case is a constant property. Swift will not let you ignore this rule.


- Non-isolated methods are particularly useful when dealing with protocol conformances such as `Hashable` and `Codable`, where we must implement methods to be run from outside the actor.

- For example, if we wanted to make our `User actor` conform to `Codable`, we’d need to implement `encode(to:)` ourselves as a non-isolated method like this:

```swift
actor User: Codable {
    enum CodingKeys: CodingKey {
        case username, password
    }

    let username: String
    let password: String
    var isOnline = false

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
    }
}

let user = User(username: "twostraws", password: "s3kr1t")

if let encoded = try? JSONEncoder().encode(user) {
    let json = String(decoding: encoded, as: UTF8.self)
    print(json)
}
```


## How to use MainActor to run code on the main queue

- `@MainActor` is a global actor that uses the main queue for executing its work.

-  In practice, this means methods or types marked with `@MainActor` can (for the most part) safely modify the UI because it will always be running on the main queue, and calling `MainActor.run()` will push some custom work of your choosing to the main actor, and thus to the main queue.

- At the simplest level both of these features are straightforward to use, but as you’ll see there’s a lot of complexity behind them.

- First, let’s look at using `@MainActor`, which automatically makes a single method or all methods on a type run on the main actor.

- This is particularly useful for any types that exist to update your user interface, such as `ObservableObject` classes.

- For example, we could create a `observable object` with two `@Published` properties, and because they will both update the UI we would mark the whole class with `@MainActor` to ensure these UI updates always happen on the main actor:

```swift
@MainActor
class AccountViewModel: ObservableObject {
    @Published var username = "Anonymous"
    @Published var isAuthenticated = false
}
```

- In fact, this set up is so central to the way `ObservableObject` works that SwiftUI bakes it right in.

- Whenever you use `@StateObject` or `@ObservedObject` inside a view, `Swift will ensure that the whole view runs on the main actor` so that you can’t accidentally try to publish UI updates in a dangerous way.

- Even better, no matter what property wrappers you use, the `body` property of your SwiftUI views is always run on the `main actor`.

- Does that mean you don’t need to explicitly add `@MainActor` to observable objects?

- Well, no – there are still benefits to using `@MainActor` with these classes, not least if they are using `async/await` to do their own asynchronous work such as downloading data from a server.

- So, my recommendation is simple: even though SwiftUI ensures main-actor-ness when using `@ObservableObject`, `@StateObject`, and SwiftUI view `body` properties, it’s a good idea to add the `@MainActor` attribute to all your observable object classes to be absolutely sure all UI updates happen on the main actor.

- If you need certain methods or computed properties to opt out of running on the main actor, use `nonisolated` as you would do with a regular actor.

- `Important:` You should `not attempt to use actors for your observable objects`, because `they must do their UI updates on the main actor rather than a custom actor`.

- More broadly, any type that has `@MainActor` objects as properties will also implicitly be `@MainActor` using global actor inference – a set of rules that Swift applies to make sure global-actor-ness works without getting in the way too much.

- The magic of `@MainActor` is that `it automatically forces methods or whole types to run on the main actor`, a lot of the time without any further work from us.

- Previously we needed to do it by hand, remembering to use code like `DispatchQueue.main.async()` or similar every place it was needed, but now the compiler does it for us automatically.

- Be careful: `@MainActor` is really helpful to make code run on the main actor, but it’s not foolproof.

- For example, if you have a `@MainActor` class then in theory all its methods will run on the main actor, but one of those methods could trigger code to run on a background task.

- For example, if you’re using Face ID and call `evaluatePolicy()` to authenticate the user, `the completion handler will be called on a background thread` even though `that code is still within the @MainActor class`.

- If you do need to spontaneously run some code on the main actor, you can do that by calling `MainActor.run()` and providing your work.

- This allows you to safely push work onto the main actor no matter where your code is currently running, like this:

```swift
func couldBeAnywhere() async {
    await MainActor.run {
        print("This is on the main actor.")
    }
}

await couldBeAnywhere()
```

- You can send back nothing from `run()` if you want, or send back a value like this:

```swift
func couldBeAnywhere() async {
    let result = await MainActor.run { () -> Int in
        print("This is on the main actor.")
        return 42
    }

    print(result)
}

await couldBeAnywhere()
```

- Even better, `if that code was already running on the main actor then the code is executed immediately` – `it won’t wait until the next run loop` in the same way that `DispatchQueue.main.async()` would have done.

- If you wanted the work to be sent off to the main actor without waiting for its result to come back, you can place it in a new task like this:

```swift
func couldBeAnywhere() {
    Task {
        await MainActor.run {
            print("This is on the main actor.")
        }
    }

    // more work you want to do
}

couldBeAnywhere()
```

- Or you can also mark your task’s closure as being `@MainActor`, like this:

```swift
func couldBeAnywhere() {
    Task { @MainActor in
        print("This is on the main actor.")
    }

    // more work you want to do
}

couldBeAnywhere()
```

- This is `particularly helpful when you’re inside a synchronous context`, so you need to `push work to the main actor without using the await` keyword.

- `Important:` If `your function is already running on the main actor`, using `await MainActor.run()` will run your code immediately without waiting for the next run loop, but using `Task` as shown above will wait for the next run loop.

- You can see this in action in the following snippet:

```swift
@MainActor class ViewModel: ObservableObject {
    func runTest() async {
        print("1")

        await MainActor.run {
            print("2")

            Task { @MainActor in
                print("3")
            }

            print("4")
        }

        print("5")
    }
}
```

- That marks the whole type as using the main actor, so the call to `MainActor.run()` will run immediately when `runTest()` is called.

- However, the inner `Task` will not run immediately, so the code will print `1, 2, 4, 5, 3`.

- Although it’s possible to create your own global actors, I think we should probably avoid doing so until we’ve had sufficient chance to build apps using what we already have.


## Understanding how global actor inference works

- Apple explicitly annotates many of its types as being `@MainActor`, including most `UIKit` types such as `UIView` and `UIButton`.

- However, there are many places where types gain main-actor-ness implicitly through a `process called global actor inference` – Swift applies `@MainActor` automatically based on a set of predetermined rules.

- There are five rules for global actor inference, and I want to tackle them individually because although they start easy they get more complex.

1- First, if a class is marked `@MainActor`, all its subclasses are also automatically `@MainActor`. This follows the principle of least surprise: `if you inherit from a @MainActor class it makes sense that your subclass is also @MainActor`.

2- Second, if a method in a class is marked `@MainActor`, any overrides for that method are also automatically `@MainActor`. Again, this is a natural thing to expect – `you overrode a @MainActor method, so the only safe way Swift can call that override is if it’s also @MainActor`.

3- Third, any struct or class using a property wrapper with `@MainActor` for its wrapped value will automatically be `@MainActor`. This is what makes `@StateObject` and `@ObservedObject` convey main-actor-ness on SwiftUI views that use them – `if you use either of those two property wrappers in a SwiftUI view, the whole view becomes @MainActor` too.

4- If a protocol declares a method as being `@MainActor`, any type that conforms to that protocol will have that same method automatically be `@MainActor` unless you separate the conformance from the method.

- What this means is that if you make a type conform to a protocol with a `@MainActor` method, and add the required method implementation at the same time, it is implicitly `@MainActor`. 

- However, if `you separate the conformance and the method implementation`, you need to add `@MainActor` by hand.

```swift
// A protocol with a single `@MainActor` method.
protocol DataStoring {
    @MainActor func save()
}

// A struct that does not conform to the protocol.
struct DataStore1 { }

// When we make it conform and add save() at the same time, our method is implicitly @MainActor.
extension DataStore1: DataStoring {
    func save() { } // This is automatically @MainActor.
}

// A struct that conforms to the protocol.
struct DataStore2: DataStoring { }

// If we later add the save() method, it will *not* be implicitly @MainActor so we need to mark it as such ourselves.
extension DataStore2 {
    @MainActor func save() { }
}
```

- As you can see, we need to explicitly use `@MainActor func save()` in `DataStore2` because the global actor inference does not apply there. 

- Don’t worry about forgetting it, though – Xcode will automatically check the annotation is there, and offer to add `@MainActor` if it’s missing.

5- If the whole protocol is marked with `@MainActor`, any type that conforms to that protocol will also automatically be `@MainActor` unless you put the conformance separately from the main type declaration, in which case `only the methods are @MainActor`.

```swift
// A protocol marked as @MainActor.
@MainActor protocol DataStoring {
    func save()
}

// A struct that conforms to DataStoring as part of its primary type definition.
struct DataStore1: DataStoring { // This struct is automatically @MainActor.
    func save() { } // This method is automatically @MainActor.
}

// Another struct that conforms to DataStoring as part of its primary type definition.
struct DataStore2: DataStoring { } // This struct is automatically @MainActor.

// The method is provided in an extension, but it's the same as if it were in the primary type definition.
extension DataStore2 {
    func save() { } // This method is automatically @MainActor.
}

// A third struct that does *not* conform to DataStoring in its primary type definition.
struct DataStore3 { } // This struct is not @MainActor.

// The conformance is added as an extension
extension DataStore3: DataStoring {
    func save() { } // This method is automatically @MainActor.
}
```

- If conformance to a `@MainActor` protocol retroactively made the whole of Apple’s type `@MainActor` then you would have dramatically altered the way it worked, probably breaking all sorts of assumptions made elsewhere in the system.

- If it’s your type – a type you’re creating from scratch in your own code – then you can add the protocol conformance as you make the type and therefore isolate the entire type to `@MainActor`, because it’s your choice.


## What is actor hopping and how can it cause problems?

- When `a thread pauses work on one actor to start work on another actor`, we call it `actor hopping`, and it will `happen any time one actor calls another`.

- Behind the scenes, Swift manages a group of threads called the `cooperative thread pool`, `creating as many threads as there are CPU cores so that we can’t be hit by thread explosion`.

- `Actors guarantee that they can be running only one method at a time`, but they `don’t care which thread they are running on` – they will automatically move between threads as needed in order to balance system resources.

- `Actor hopping with the cooperative pool is fast` – it will happen automatically, and we don’t need to worry about it.

- However, the `main thread is not part of the cooperative thread pool`, which means `actor code being run from the main actor will require a context switch`, which will incur a `performance penalty if done too frequently`.

- You can see the problem caused by frequent actor hopping in this toy example code:

```swift
actor NumberGenerator {
    var lastNumber = 1

    func getNext() -> Int {
        defer { lastNumber += 1 }
        return lastNumber
    }

    @MainActor func run() async {
        for _ in 1...100 {
            let nextNumber = await getNext()
            print("Loading \(nextNumber)")
        }
    }
}

let generator = NumberGenerator()
await generator.run()
```

- In that code, the `run()` method must take place on the `main actor` because it has the `@MainActor` attribute attached to it, however the `getNext()` method will run somewhere on the `cooperative pool`, meaning that `Swift will need to perform frequent context switching from to and from the main actor inside the loop`.

- In practice, your code is more likely to look like this:

```swift
// An example piece of data we can show in our UI
struct User: Identifiable {
    let id: Int
}

// An actor that handles serial access to a database
actor Database {
    func loadUser(id: Int) -> User {
        // complex work to load a user from the database
        // happens here; we'll just send back an example
        User(id: id)
    }
}

// An observable object that handles updating our UI
@MainActor
class DataModel: ObservableObject {
    @Published var users = [User]()
    var database = Database()

    // Load all our users, updating the UI as each one
    // is successfully fetched
    func loadUsers() async {
        for i in 1...100 {
            let user = await database.loadUser(id: i)
            users.append(user)
        }
    }
}

// A SwiftUI view showing all the users in our data model
struct ContentView: View {
    @StateObject var model = DataModel()

    var body: some View {
        List(model.users) { user in
            Text("User \(user.id)")
        }
        .task {
            await model.loadUsers()
        }
    }
}
```

- When that runs, the `loadUsers()` method will run on the `main actor`, because the whole `DataModel` class must run there – it has been annotated with `@MainActor` to avoid publishing changes from a background thread.

- However, the database’s `loadUser()` method will `run somewhere on the cooperative pool`: it might run on thread 3 the first time it’s called, thread 5 the second time, thread 8 the third time, and so on; Swift will take care of that for us.

- This means when our code runs it `will repeatedly hop to and from the main actor`, meaning there’s a `significant performance cost introduced by all the context switching`.

- The solution here is to `avoid all the switches by running operations in batches` – hop to the cooperative thread pool once to perform all the actor work required to load many users, then process those batches on the main actor.

- The batch size could potentially load all users at once depending on your need, but even batch sizes of two would halve the context switches compared to individual fetches.

- For example, we could rewrite our previous example like this:

```swift
struct User: Identifiable {
    let id: Int
}

actor Database {
    func loadUsers(ids: [Int]) -> [User] {
        // complex work to load users from the database
        // happens here; we'll just send back examples
        ids.map { User(id: $0) }
    }
}

@MainActor
class DataModel: ObservableObject {
    @Published var users = [User]()
    var database = Database()

    func loadUsers() async {
        let ids = Array(1...100)

        // Load all users in one hop
        let newUsers = await database.loadUsers(ids: ids)

        // Now back on the main actor, update the UI
        users.append(contentsOf: newUsers)
    }
}

struct ContentView: View {
    @StateObject var model = DataModel()

    var body: some View {
        List(model.users) { user in
            Text("User \(user.id)")
        }
        .task {
            await model.loadUsers()
        }
    }
}
```

- Notice how the SwiftUI view is identical – we’re just rearranging our internal data access to be more efficient.


## What is the difference between actors classes and structs?

- Swift provides `four concrete nominal types for defining custom objects`: `actors`, `classes`, `structs`, and `enums`.

- `Tip`: Ultimately, which you use depends on the exact context you’re working in, and you will need them all at some point.

- Actors:

1. Are `reference types`, so are good for `shared mutable state`.

2. Can have properties, methods, initializers, and subscripts.

3. Do not support inheritance.

4. Automatically conform to the `Actor` protocol.

5. Automatically conform to the `AnyObject` protocol, and can therefore conform to `Identifiable` without adding an explicit `id` property.

6. Can have a deinitializer.

7. Cannot have their public properties and methods directly accessed externally, we must use `await`.

8. Can `execute only one method at a time`, regardless of how they are accessed.


- Classes:

1. Are reference types, so are good for shared mutable state.

2. Can have properties, methods, initializers, and subscripts.

3. Support inheritance.

4. Cannot conform to the `Actor` protocol.

5. Automatically conform to the `AnyObject` protocol, and can therefore conform to `Identifiable` without adding an explicit `id` property.

6. Can have a deinitializer.

7. Can have their public properties and methods directly accessed externally.

8. Can potentially be executing severals methods at a time.


- Structs:

1. Are value types, so are copied rather than shared.

2. Can have properties, methods, initializers, and subscripts.

3. Do not support inheritance.

4. Cannot conform to the `Actor` protocol.

5. Cannot conform to the `AnyObject` protocol; if you want to add `Identifiable` conformance you must add an `id` property yourself.

6. Cannot have a deinitializer.

7. Can have their public properties and methods directly accessed externally.

8. Can potentially be executing severals methods at a time.

- You might think the advantages of actors are such that they should be used everywhere classes are currently used, but `that is a bad idea`.

- Not only do you `lose the ability for inheritance`, but you’ll also cause a huge amount of pain for yourself because `every single external property access needs to use await`.

- However, there are certainly places where actors are a natural fit.

- If you were previously creating serial queues to handle specific workflows, they can be replaced almost entirely with `actors` – while also benefiting from increased safety and performance.

- So, `if you have some work that absolutely must work one at a time`, `such as accessing a database`, then `try converting it into something like a database actor`.

- There is `one area in particular where using actors rather than classes is going to cause problems`:

- `Do not use actors for your SwiftUI data models`.

- You should use a `class` that conforms to the `ObservableObject` protocol instead.

- If needed, you can optionally also mark that `class` with `@MainActor` to ensure it `does any UI work safely`, but keep in mind that using `@StateObject` or `@ObservedObject` automatically `makes a view’s code run on the main actor`.

- If you desperately need to be able to `carve off some async work safely`, you can `create a sibling actor` – a `separate actor that does not use @MainActor`, but `does not directly update the UI`.


## Do not use an actor for your SwiftUI data models

- Swift’s `actors allow us to share data in multiple parts of our app without causing problems with concurrency`, because `they automatically ensure two pieces of code cannot simultaneously access the actor’s protected data`.

- Actors are an important addition to our toolset, and `help us guarantee safe access to data in concurrent environments`.

- `Actors are a really bad choice for any data models you use with SwiftUI` – anything that conforms to the `ObservableObject` protocol.

- SwiftUI `updates its user interface on the main actor`, which means when we make a `class` conform to `ObservableObject` we’re agreeing that all our work will happen on the `main actor`. 

- As an example, any time we modify an `@Published` property `that must happen on the main actor`, otherwise we’ll be asking for changes to be made somewhere that isn’t allowed.

- Now think about what would happen if you tried to use a `custom actor` for your data. 

- Not only would any data writes need to happen on that `actor` rather than the `main actor` (thus `forcing the UI to update away from the main actor`), but `any data reads would need to happen there too` – every time you tried to bind a string to a TextField, for example, you’d be asking Swift to simultaneously use the `main actor` and your `custom actor`, which doesn’t make sense.

- The correct solution here is to use a class that conforms to `ObservableObject`, then annotate it with `@MainActor` to `ensure it does any UI work safely`.

- If you still find that `you need to be able to carve off some async work safely`, you can create a `sibling actor` – `a separate actor that does not use @MainActor`, but `does not directly update the UI`.


## How to download JSON from the internet and decode it into any Codable type

- Fetching JSON from the network and using `Codable` to convert it into native Swift objects is probably the most common task for any Swift developer, usually followed by displaying that data in a `List` or `UITableView` depending on whether they are using `SwiftUI` or `UIKit`.

- Well, using Swift’s `concurrency` features we can write a small but beautiful `extension for URLSession` that makes such work just a single line of code – you just tell iOS what data type to expect and the URL to fetch, and it will do the rest.

- To add some extra flexibility, we can also provide options to customize decoding strategies for keys, data, and dates, providing sensible defaults for each one to keep our call sites clear for the most common usages.

```swift
extension URLSession {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) async throws  -> T {
    
        let (data, _) = try await data(from: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy

        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }
}
```

- That does several things:

1. It’s an extension on `URLSession`, so you can go ahead and create your own custom session with a unique configuration if needed.

2. It uses generics, so that it will work with anything that conforms to the `Decodable` protocol – that’s half of `Codable`, so if you use `Codable` it will work there too.

3. It uses `T.self` for the default data type, so if Swift can infer your type then you don’t need to repeat yourself.

4. It `allows all errors to propane to your call site`, so you can `handle networking and/or decoding errors` as needed.

- To use the extension in your own code, first define a type you want to work with, then go ahead and call `decode()` in whichever way you need:

```swift
struct User: Codable {
    let id: UUID
    let name: String
    let age: Int
}

struct Message: Codable {
    let id: Int
    let user: String
    let text: String
}

do {
    // Fetch and decode a specific type
    let url1 = URL(string: "https://hws.dev/user-24601.json")!
    let user = try await URLSession.shared.decode(User.self, from: url1)
    print("Downloaded \(user.name)")

    // Infer the type because Swift has a type annotation
    let url2 = URL(string: "https://hws.dev/inbox.json")!
    let messages: [Message] = try await URLSession.shared.decode(from: url2)
    print("Downloaded \(messages.count) messages")

    // Create a custom URLSession and decode a Double array from that
    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    let session = URLSession(configuration: config)

    let url3 = URL(string: "https://hws.dev/readings.json")!
    let readings = try await session.decode([Double].self, from: url3)
    print("Downloaded \(readings.count) readings")
} catch {
    print("Download error: \(error.localizedDescription)")
}
```

- As you can see, with that small extension in place it becomes trivial to fetch and decode any type of `Codable` data with just one line of Swift.

