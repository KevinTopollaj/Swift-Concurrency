# Task and TaskGroup

## Table of contents

* [What are tasks and task groups?](#What-are-tasks-and-task-groups)
* [How to create and run a task](#How-to-create-and-run-a-task)
* [What is the difference between a task and a detached task?](#What-is-the-difference-between-a-task-and-a-detached-task)
* [How to get a Result from a task](#How-to-get-a-Result-from-a-task)
* [How to control the priority of a task](#How-to-control-the-priority-of-a-task)
* [Understanding how priority escalation works](#Understanding-how-priority-escalation-works)
* [How to cancel a Task](#How-to-cancel-a-Task)
* [How to make a task sleep](#How-to-make-a-task-sleep)
* [How to voluntarily suspend a task](#How-to-voluntarily-suspend-a-task)
* [How to create a task group and add tasks to it](#How-to-create-a-task-group-and-add-tasks-to-it)
* [How to cancel a task group](#How-to-cancel-a-task-group)
* [How to handle different result types in a task group](#How-to-handle-different-result-types-in-a-task-group)
* [What is the difference between async let tasks and task groups?](#What-is-the-difference-between-async-let-tasks-and-task-groups)
* [How to make async command line tools and scripts](#How-to-make-async-command-line-tools-and-scripts)
* [How to create and use task local values](#How-to-create-and-use-task-local-values)
* [How to run tasks using SwiftUI task modifier](#How-to-run-tasks-using-SwiftUI-task-modifier)
* [Is it efficient to create many tasks](#Is-it-efficient-to-create-many-tasks)



## What are tasks and task groups?

- Using `async/await` in Swift allows us to `write asynchronous code` that is easy to read and understand, but by itself it `doesn’t enable us to run anything concurrently` – even with several CPU cores working hard, `async/await code would still execute sequentially`.

- To `create actual concurrency` – to `provide the ability for multiple pieces of work to run at the same time` – Swift provides us with two specific types for constructing and managing concurrency in a way that makes it easier to use: `Task` and `TaskGroup`.

- Although the types themselves aren’t complex, they unlock a lot of power and flexibility, and sit at the core of how we use concurrency with Swift.

- Which you choose – `Task` or `TaskGroup` – depends on the goal of your work:

- If you want one or two independent pieces of work to start, then `Task` is the right choice.

- If you want to split up one job into several concurrent operations then `TaskGroup` is a better fit.

- `Task groups` work best when their individual operations `return exactly the same kind of data`, but with a little extra effort you can coerce them into supporting heterogenous data types.

- Although you might not realize it, `you’re using tasks` every time you write any `async code` in Swift.

- You see, `all async functions run as part of a task` whether or not we explicitly ask for it to happen.

- Even using `async let` is syntactic sugar for `creating a task then waiting for its result`.

- This is why `if you use multiple sequential async let calls they will all start executing immediately` while the rest of your code continues.

- Both `Task` and `TaskGroup` can be created with `one of four priority levels`: 

- `high` is the most important, then `medium`, `low`, and finally `background` at the bottom.

- Task priorities allow the system to adjust the order in which it executes work, meaning that important work can happen before unimportant work.

- Tip: If you’ve been doing iOS programming for a while, you may prefer to use the more familiar `quality of service` priorities from `DispatchQueue`, which are `userInitiated` and `utility` in place of `high` and `low` respectively. 

- There is no equivalent to the old `userInteractive` priority, which `is now exclusively reserved for the user interface`.


## How to create and run a task

- Swift `Task` struct lets us `start running some work immediately`, and `optionally wait for the result to be returned`. 

- And it is optional: sometimes you don’t care about the result of the task, or sometimes the task automatically updates some external value when it completes, so you can just use them as “fire and forget” operations if you need to. 

- This makes them `a great way to run async code from a synchronous function`.

- First, let’s look at an example where we `create two tasks back to back`, then `wait for them both to complete`. 

- This will fetch data from two different URLs, decode them into two different structs, then print a summary of the results, all to simulate a user starting up a game – what are the latest news updates, and what are the current highest scores?

```swift
struct NewsItem: Decodable {
    let id: Int
    let title: String
    let url: URL
}

struct HighScore: Decodable {
    let name: String
    let score: Int
}

func fetchUpdates() async {

    let newsTask = Task { () -> [NewsItem] in
        let url = URL(string: "https://hws.dev/headlines.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([NewsItem].self, from: data)
    }

    let highScoreTask = Task { () -> [HighScore] in
        let url = URL(string: "https://hws.dev/scores.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([HighScore].self, from: data)
    }

    do {
        let news = try await newsTask.value
        let highScores = try await highScoreTask.value
        
        print("Latest news loaded with \(news.count) items.")

        if let topScore = highScores.first {
            print("\(topScore.name) has the highest score with \(topScore.score), out of \(highScores.count) total results.")
        }
    } catch {
        print("There was an error loading user data.")
    }
    
}

await fetchUpdates()
```

- Let’s unpick the key parts:

1- Creating and running a task is done by using its initializer, passing in the work you want to do.

2- Tasks don’t always need to return a value, but when they do chances are you’ll need to declare exactly what as you create the task – I’ve said `() -> [NewsItem]` in, for example.

3- As soon as you create the task it will start running.

4- The entire task is run concurrently with your other code, which means it might be able to run in parallel too. In our case, that means fetching and decoding the data happens inside the task, which keeps our main `fetchUpdates()` function free.

5- If you want to read the return value of a task, you need to access its `value` property using `await`. In our case our task could also throw errors because we’re accessing the network, so we need to use `try` as well.

6- Once you’ve copied out the value from your task you can use that normally without needing `await` or `try` again, although subsequent accesses to the task itself – e.g. `newsTask.value` – will need `try await` because Swift can’t statically determine that the value is already present.


- Both tasks in that example returned a value, but that’s not a requirement – the “fire and forget” approach allows us to create a task without storing it, and Swift will ensure it runs until completion correctly.

- To demonstrate this, we could make a small SwiftUI program to fetch a user’s inbox when a button is pressed. 
- `Button actions are not async functions`, so we need to `launch a new task inside the action`. 
- The `task` can `call async functions`, but in this instance we don’t actually care about the result so we’re not going to store the task – the function it calls will handle updating our SwiftUI view.

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let text: String
}

struct ContentView: View {
    @State private var messages = [Message]()

    var body: some View {
        NavigationView {
            Group {
                if messages.isEmpty {
                    Button("Load Messages") {
                        Task {
                            await loadMessages()
                        }
                    }
                } else {
                    List(messages) { message in
                        VStack(alignment: .leading) {
                            Text(message.from)
                                .font(.headline)

                            Text(message.text)
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
        }
    }
    
    func loadMessages() async {
        do {
            let url = URL(string: "https://hws.dev/messages.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(id: 0, from: "Failed to load inbox.", text: "Please try again later.")
            ]
        }
    }
    
}
```

- Even though that code isn’t so different from the previous example, I still want to pick out a few things:

1- Creating the new `task` is what allows us to `start calling an async function even though the button’s action is a synchronous function`.

2- The `lifetime of the task is not bound by the button’s action closure`. So, even though the closure will finish immediately, the task it created will carry on running to completion.

3- We aren’t trying to read a return value from the task, or storing it anywhere. This task doesn’t actually return anything, and doesn’t need to.

- I know it’s a not a lot of code, but between `Task`, `async/await`, and `SwiftUI` a lot of work is happening on our behalf. 

- Remember, when we use `await` we’re signaling a potential suspension point, and when our functions resume they might be on the same thread as before or they might not.

- In this case there are potentially four thread swaps happening in our code:

1- All UI work runs on the main thread, so the button’s action closure will fire on the main thread.

2- Although we create the task on the main thread, the work we pass to it will execute on a background thread.

3- Inside `loadMessages()` we use `await` to load our URL data, and when that resumes we have another potential thread switch – we might be on the same background thread as before, or on a different background thread.

4- Finally, the `messages` property uses the `@State` property wrapper, which will automatically update its value on the main thread. So, even though we assign to it on a background thread, the actual update will get silently pushed back to the main thread.

- Best of all, we don’t have to care about this – we don’t need to know how the system is balancing the threads, or even that the threads exist, because Swift and SwiftUI take care of that for us. 

- In fact, the concept of `tasks` is so thoroughly baked into SwiftUI that there’s a dedicated `task()` modifier that makes them even easier to use.


## What is the difference between a task and a detached task?

- If you create a new `task` using the regular `Task` initializer, your work starts running immediately and inherits the priority of the caller, any task local values, and its actor context. 

- On the other hand, `detached tasks` also start work immediately, but do not inherit the priority or other information from the caller.

- The Swift Evolution proposal for `async let`: “`Task.detached` most of the time should not be used at all.”, getting that out of the way up front so you don’t spend time learning about `detached tasks`, only to realize you probably shouldn’t use them!

- Let’s dig in to our three differences: `priority`, `task local values`, and `actor isolation`.

- The `priority` part is straightforward: `if you’re inside a user-initiated task and create a new task, it will also have a priority of user-initiated`, whereas `creating a new detached task would give a nil priority unless you specifically asked for something`.

- `Task local values` allow us to `share a specific value everywhere inside one specific task` – they are like static properties on a type, except `rather than everything sharing that property, each task has its own value`.

- `Detached tasks` do not inherit the task local values of their parent because they do not have a parent.

- The `actor context` part is more important and more complex. When you `create a regular task from inside an actor it will be isolated to that actor`, which means `you can use other parts of the actor synchronously`:

```swift
actor User {

    func login() {
        Task {
            if authenticate(user: "taytay89", password: "n3wy0rk") {
                print("Successfully logged in.")
            } else {
                print("Sorry, something went wrong.")
            }
        }
    }

    func authenticate(user: String, password: String) -> Bool {
        // Complicated logic here
        return true
    }
}

let user = User()
await user.login()
```

- In comparison, a `detached task` `runs concurrently with all other code, including the actor that created it` – it effectively has no parent, and therefore `has greatly restricted access to the data inside the actor`.

- So, if we were to rewrite the previous actor to use a `detached task`, it would need to call `authenticate()` like this:

```swift
actor User {

    func login() {
        Task.detached {
            if await self.authenticate(user: "taytay89", password: "n3wy0rk") {
                print("Successfully logged in.")
            } else {
                print("Sorry, something went wrong.")
            }
        }
    }

    func authenticate(user: String, password: String) -> Bool {
        // Complicated logic here
        return true
    }
}

let user = User()
await user.login()
```

- This distinction is particularly important when you are running on the `main actor`, which will be the case if you’re responding to a button click for example. 

- The rules here might not be immediately obvious, so I want to show you some examples of what is allowed and what is not allowed, and more importantly explain why each is the case.

- First, if you’re changing the value of an `@State` property, you can do so using a regular task like this:

```swift
struct ContentView: View {
    @State private var name = "Anonymous"

    var body: some View {
        VStack {
            Text("Hello, \(name)!")
            Button("Authenticate") {
                Task {
                    name = "Taylor"
                }
            }
        }
    }
}
```

- Note: The `Task` here is of course not needed because we’re just setting a local value; I’m just trying to illustrate how regular tasks and detached tasks are different.

- In fact, because `@State` guarantees `it’s safe to change its value on any thread`, we can use a `detached task` instead even though it `won’t inherit actor isolation`:

```swift
struct ContentView: View {
    @State private var name = "Anonymous"

    var body: some View {
        VStack {
            Text("Hello, \(name)!")
            Button("Authenticate") {
                Task.detached {
                    name = "Taylor"
                }
            }
        }
    }
    
}
```

- The rules change when we switch to an `observable object` that publishes changes. 

- As soon as you add any `@ObservedObject` or `@StateObject` property wrappers to a view, `Swift will automatically infer that the whole view must also run on the main actor.`

- This makes sense if you think about it: `changes published by observable objects must update the UI on the main thread`, and because any part of the view might try to adjust your object the only safe approach is for the whole view to run on the main actor.

- So, this means `we can modify a view model` from inside a task created inside a SwiftUI view:

```swift
class ViewModel: ObservableObject {
    @Published var name = "Hello"
}

struct ContentView: View {
    @StateObject private var model = ViewModel()

    var body: some View {
        VStack {
            Text("Hello, \(model.name)!")
            Button("Authenticate") {
                Task {
                    model.name = "Taylor"
                }
            }
        }
    }
}
```

- However, we cannot use `Task.detached` here – `Swift will throw up an error that a property isolated to global actor 'MainActor' can not be mutated from a non-isolated context`. 

- In simpler terms, our `view model updates the UI and so must be on the main actor`, but our `detached task does not belong to that actor`.

- At this point, you might wonder why detached tasks would have any use. Well, consider this code:

```swift
class ViewModel: ObservableObject { }

struct ContentView: View {
    @StateObject private var model = ViewModel()

    var body: some View {
        Button("Authenticate", action: doWork)
    }

    func doWork() {
        Task {
            for i in 1...10_000 {
                print("In Task 1: \(i)")
            }
        }

        Task {
            for i in 1...10_000 {
                print("In Task 2: \(i)")
            }
        }
    }
    
}
```

- That’s the simplest piece of code that demonstrates the usefulness of `detached tasks`: `a SwiftUI view monitoring an empty view model`, plus a `button that launches a couple of tasks to print out text`.

- When that runs, you’ll see `“In Task 1” printed 10,000 times`, then `“In Task 2” printed 10,000 times` – even though `we have created two tasks, they are executing sequentially`. 

- This happens because our `@StateObject` `view model` `forces the entire view onto the main actor`, meaning that `it can only do one thing at a time`.

- In contrast, if you change both `Task` initializers to `Task.detached`, you’ll see `“In Task 1” and “In Task 2” get intermingled as both execute at the same time`. 

- Without any need for actor isolation, `Swift can run those tasks concurrently` – using a `detached task` has allowed us to shed our attachment to the main actor.

- Although `detached tasks` do have very specific uses, generally I think `they should be your last port of call` – use them only if you’ve tried both a regular `task` and `async let`, and neither solved your problem.


## How to get a Result from a task

- If you want to read the return value from a `Task` directly, you should read its `value` using `await`, or use `try await` if it has a throwing operation.

- However, all `tasks` also have a `result` property that returns an instance of Swift’s `Result` struct, generic over the type returned by the task as well as whether it might contain an error or not.

- To demonstrate this, we could write some code that `creates a task to fetch and decode a string from a URL`. 

- To start with we’re going to make this task throw errors if the download fails, or if the data can’t be converted to a string.

```swift
enum LoadError: Error {
    case fetchFailed, decodeFailed
}

func fetchQuotes() async {

    let downloadTask = Task { () -> String in
        let url = URL(string: "https://hws.dev/quotes.txt")!
        let data: Data

        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw LoadError.fetchFailed
        }

        if let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            throw LoadError.decodeFailed
        }
    }

    let result = await downloadTask.result

    do {
        let string = try result.get()
        print(string)
    } catch LoadError.fetchFailed {
        print("Unable to fetch the quotes.")
    } catch LoadError.decodeFailed {
        print("Unable to convert quotes to text.")
    } catch {
        print("Unknown error.")
    }
}

await fetchQuotes()
```

- There’s not a lot of code there, but there are a few things I want to point out as being important:

1- Our `task` might `return a string`, but also might `throw one of two errors`. So, when we ask for its `result` property we’ll be given a `Result<String, Error>`.

2- Although we need to use `await` to get the `result`, `we don’t need to use try` even though there could be errors there. This is because we’re just reading out the result, not trying to read the successful value.

3- We call `get()` on the `Result` object to read the successful, but that’s when `try` is needed because it’s when Swift checks whether an error occurred or not.

4- When it comes to catching errors, we need a “catch everything” block at the end, even though we know we’ll only throw `LoadError`.


- That last point hits us because Swift isn’t able to evaluate the task to see exactly what kinds of error are thrown inside, and there’s no way of adding that annotation ourself because Swift doesn’t support typed throws.

- If you don’t care what errors are thrown, or don’t mind digging through Foundation’s various errors yourself, you can avoid handling errors in the task and just let them propagate up:

```swift
func fetchQuotes() async {

    let downloadTask = Task { () -> String in
        let url = URL(string: "https://hws.dev/quotes.txt")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }

    let result = await downloadTask.result

    do {
        let string = try result.get()
        print(string)
    } catch {
        print("Unknown error.")
    }
}

await fetchQuotes()
```

- The main take aways here are:

1- All tasks can return a `Result` if you want.

2- For the error type, the `Result` will either contain `Error` or `Never`.

3- Although we need to use `await` to get the result, we don’t need to use `try` until we try to get the success value inside.

- Many places where `Result` was useful are now better served through `async/await`, but `Result` is still `useful for storing in a single value the success or failure of some operation`.

- In the code above we evaluate the result immediately for brevity, but the power of `Result` is that `it’s value you can pass around elsewhere in your code to deal with at a later time`.

 
## How to control the priority of a task

- Swift tasks can have a priority attached to them, such as `.high` or `.background`, but the priority can also be `nil` if no specific priority was assigned.

- This priority can be used by the system to determine which task should be executed next, but this isn’t guaranteed – think of it as a suggestion rather than a rule.

- Creating a task with a priority look like this:

```swift
func fetchQuotes() async {

    let downloadTask = Task(priority: .high) { () -> String in
        let url = URL(string: "https://hws.dev/chapter.txt")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }

    do {
        let text = try await downloadTask.value
        print(text)
    } catch {
        print(error.localizedDescription)
    }
}

await fetchQuotes()
```

- You can directly assign a priority to a task when it’s created, if you don’t then Swift will follow three rules for deciding the priority automatically:

1- If the task was created from another task, the child task will inherit the priority of the parent task.

2- If the new task was created directly from the main thread as opposed to a task, it’s automatically assigned the highest priority of `.userInitiated`.

3- If the new task wasn’t made by another task or the main thread, Swift will try to query the priority of the thread or give it a `nil` priority.

- `This means not specifying an exact priority is often a good idea because Swift will do The Right Thing.`

- However, like I said you can also specify an exact priority from one of the following:

- The highest priority is `.high`, which is synonymous with `.userInitiated`. As the name implies, this should be used only for tasks that the user specifically started and is actively waiting for.

- Next highest is `medium`, and again as the name implies this is a great choice for most of your tasks that the user isn’t actively waiting for.

- Next is `.low`, which is synonymous with `.utility`. This is the best choice for anything long enough to require a progress bar to be displayed, such as copying files or importing data.

- The lowest priority is `.background`, which is for any work the user can’t see, such as building a search index. This could in theory take hours to complete.

- Like I said, priority inheritance helps get us a sensible priority by default, particularly when creating tasks in response to a user interface action.

- For example, we could build a simple SwiftUI app using a single task, and we don’t need to provide a specific priority –it will automatically run as high priority because it was started from our UI:

```swift
struct ContentView: View {
    @State private var jokeText = ""

    var body: some View {
        VStack {
            Text(jokeText)
            Button("Fetch new joke", action: fetchJoke)
        }
    }

    func fetchJoke() {
        Task {
            let url = URL(string: "https://icanhazdadjoke.com")!
            var request = URLRequest(url: url)
            request.setValue("Swift Concurrency by Example", forHTTPHeaderField: "User-Agent")
            request.setValue("text/plain", forHTTPHeaderField: "Accept")

            let (data, _) = try await URLSession.shared.data(for: request)

            if let jokeString = String(data: data, encoding: .utf8) {
                jokeText = jokeString
            } else {
                jokeText = "Load failed."
            }
        }
    }
}
```

- Any task can query its current priority using `Task.currentPriority`, but this works from anywhere – if it’s called in a function that is not currently part of a task, Swift will query the system for an answer or send back `.medium`.


## Understanding how priority escalation works

- Every `task` can be `created with a specific priority level`, or `it can inherit a priority from somewhere else`.

- But in two specific circumstances, `Swift will raise the priority of a task` so it’s able to complete faster.

- This always happens because of some specific action from us:

1- If higher-priority task A starts waiting for the result of lower-priority task B, task B will have its priority elevated to the same priority as task A.

2- If lower-priority task A has started running on an actor, and higher-priority task B has been enqueued on that same actor, task A will have its priority elevated to match task B.

- In both cases, Swift is trying to ensure the higher priority task gets the quality of service it needs to run quickly.

- If something very important can only complete when something less important is also complete, then the less important task becomes very important.

- For the most part, this isn’t something we need to worry about in our code – think of it as a bonus feature provided automatically by Swift’s tasks.

- However, there is one place where priority escalation might surprise you, and it’s worth at least being aware of it:

- In our first situation, where a high-priority task uses `await` on a low-priority task, using `Task.currentPriority` will report the `escalated priority` rather than the original priority. 

- So, you might create a task with a low priority, but when you query it a minute later it might have moved up to be a high priority.

- The other situation – if you queue a high-priority task on the same actor where a low-priority task is already running – will also involve priority escalation, but won’t change the value of `.currentPriority`.

- This means your task will run a little faster and it might not be obvious why, but honestly it’s unlikely you’ll even notice this.


## How to cancel a Task

- Swift’s tasks use `cooperative cancellation`, which means that although we can tell a task to stop work, the task itself is free to completely ignore that instruction and carry on for as long as it wants.

- This is a feature rather than a bug: if cancelling a task made it stop work immediately, the task might leave your program in an inconsistent state.

- There are seven things to know when working with task cancellation:

1- You can explicitly cancel a task by calling its `cancel()` method.

2- Any task can check `Task.isCancelled` to determine whether the task has been cancelled or not.

3- You can call the `Task.checkCancellation()` method, which will throw a `CancellationError` if the task has been cancelled or do nothing otherwise.

4- Some parts of Foundation automatically check for task cancellation and will throw their own cancellation error even without your input.

5- If you’re using `Task.sleep()` to wait for some amount of time to pass, that will not honor cancellation requests – the task will still sleep even when cancelled.

6- If the task is part of a group and any part of the group throws an error, the other tasks will be cancelled and awaited.

7- If you have started a task using SwiftUI’s `task()` modifier, that task will automatically be canceled when the view disappears.

- We can explore a few of these in code. First, here’s a function that uses a task to fetch some data from a URL, decodes it into an array, then returns the average:

```swift
func getAverageTemperature() async {

    let fetchTask = Task { () -> Double in
        let url = URL(string: "https://hws.dev/readings.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let readings = try JSONDecoder().decode([Double].self, from: data)
        let sum = readings.reduce(0, +)
        return sum / Double(readings.count)
    }

    do {
        let result = try await fetchTask.value
        print("Average temperature: \(result)")
    } catch {
        print("Failed to get data.")
    }
}

await getAverageTemperature()
```

- Now, there is no explicit cancellation in there, but there is implicit cancellation because the `URLSession.shared.data(from:)` call will check to see whether its task is still active before continuing.

- If the task has been cancelled, `data(from:)` will automatically throw a `URLError` and the rest of the task won’t execute.

- However, that implicit check happens before the network call, so it’s unlikely to be an actual cancellation point in practice.

- As most of our users are likely to be using mobile network connections, the network call is likely to take most of the time of this task, particularly if the user has a poor connection.

- So, we could upgrade our task to explicitly check for cancellation after the network request, using `Task.checkCancellation()`.

- This is a static function call because it will always apply to whatever task it’s called inside, and it needs to be called using `try` so that it can throw a `CancellationError` if the task has been cancelled. 

- Here’s the new function:

```swift
func getAverageTemperature() async {

    let fetchTask = Task { () -> Double in
        let url = URL(string: "https://hws.dev/readings.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try Task.checkCancellation()
        
        let readings = try JSONDecoder().decode([Double].self, from: data)
        let sum = readings.reduce(0, +)
        return sum / Double(readings.count)
    }

    do {
        let result = try await fetchTask.value
        print("Average temperature: \(result)")
    } catch {
        print("Failed to get data.")
    }
}

await getAverageTemperature()
```

- As you can see, it just takes one call to `Task.checkCancellation()` to make sure our task isn’t wasting time calculating data that’s no longer needed.

- If you want to handle cancellation yourself – if you need to clean up some resources or perform some other calculations, for example – then instead of calling `Task.checkCancellation()` you should check the value of `Task.isCancelled` instead.

- This is a simple Boolean that returns the current cancellation state, which you can then act on however you want.

- To demonstrate this, we could rewrite our function a third time so that cancelling the task or failing to fetch data returns an average temperature of 0. 

- This time we’re going to cancel the task ourselves as soon as it’s created, but because we’re always returning a default value we no longer need to handle errors when reading the task’s result:

```swift
func getAverageTemperature() async {

    let fetchTask = Task { () -> Double in
        let url = URL(string: "https://hws.dev/readings.json")!

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if Task.isCancelled { return 0 }

            let readings = try JSONDecoder().decode([Double].self, from: data)
            let sum = readings.reduce(0, +)
            return sum / Double(readings.count)
        } catch {
            return 0
        }
    }

    fetchTask.cancel()

    let result = await fetchTask.value
    print("Average temperature: \(result)")
}

await getAverageTemperature()
```

- Now we have one `implicit cancellation point` with the `data(from:)` call, and an `explicit one` with the check on `Task.isCancelled`. 

- If either one is triggered, the task will return 0 rather than throw an error.

- Tip: You can use both `Task.checkCancellation()` and `Task.isCancelled` from both synchronous and asynchronous functions.

- Remember, `async functions can call synchronous functions freely`, so checking for cancellation can be just as important to avoid doing unnecessary work.


## How to make a task sleep

- Swift’s `Task` struct has a static `sleep()` method that will cause the current task to be suspended for at least some number of nanoseconds.

- Yes, nanoseconds: you need to write `1_000_000_000 to get 1 second`.

- You need to call `Task.sleep()` using `await` as it will cause the task to be suspended, and you also need to use `try` because `sleep()` will throw an error if the task is cancelled.

- For example, this will make the current task sleep for at least 3 seconds:

```swift
try await Task.sleep(nanoseconds: 3_000_000_000)
```

- `Important:` Calling `Task.sleep()` will make the current task `sleep for at least the amount of time` you ask, `not exactly the time you ask`.

- There is a little drift involved because the system might be busy doing other work when the sleep ends, but you are at least guaranteed it won’t end before your time has elapsed.

- Using nanoseconds is a bit clumsy, but Swift doesn’t have an alternative at this time – the plan seems to be to wait for a more thorough review of managing time in the language before committing to specific API.

- In the meantime, we can add small `Task extensions` to make sleeping easier to accomplish. 

- For example, this lets us sleep using seconds as a floating-point number:

```swift
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
```

- With that in place, you can now write `Task.sleep(seconds: 0.5)` or similar.

- Calling `Task.sleep()` automatically checks for cancellation, meaning that if you cancel a sleeping task it will be woken and throw a `CancellationError` for you to catch.

- `Tip:` Unlike making a thread sleep, `Task.sleep()` does not block the underlying thread, allowing it pick up work from elsewhere if needed.


## How to voluntarily suspend a task

- If you’re `executing a long-running task` that has few if any suspension points, for example `if you’re repeatedly iterating over an intensive loop`, you can `call Task.yield()` to voluntarily `suspend the current task so that Swift can give other tasks the chance to proceed a little if needed`.

- To demonstrate this, we could write a simple function to calculate the factors for a number – numbers that divide another number equally.

- For example, the factors for 12 are 1, 2, 3, 4, 6, and 12. A simple version of this function might look like this:

```swift
func factors(for number: Int) async -> [Int] {
    var result = [Int]()

    for check in 1...number {
        if number.isMultiple(of: check) {
            result.append(check)
        }
    }

    return result
}

let factors = await factors(for: 120)
print("Found \(factors.count) factors for 120.")
```

- Despite being a pretty inefficient implementation, in release builds that will still execute quite fast even for numbers such as 100,000,000. 

- But if you try something even bigger you’ll notice it struggles – running hundreds of millions of checks is really going to make the task chew up a lot of CPU time, which might mean other tasks are left sitting around unable to make even the slightest progress forward.

- Keep in mind our other tasks might be able to kick off some work then suspend immediately, such as making network requests.

- A `simple improvement` is to `force our factors() method to pause every so often` so that Swift can run other tasks if it wants – we’re effectively asking it to come up for air and let another task have a go.

- So, we could modify the function so that it calls `Task.yield()` every `100,000` numbers, like this:

```swift
func factors(for number: Int) async -> [Int] {
    var result = [Int]()

    for check in 1...number {
        if check.isMultiple(of: 100_000) {
            await Task.yield()
        }

        if number.isMultiple(of: check) {
            result.append(check)
        }
    }

    return result
}

let factors = await factors(for: 120)
print("Found \(factors.count) factors for 120.")
```

- However, that has the downside of now having twice as much work in the loop. 

- As an alternative, you could `try yielding only when a multiple is actually found`, like this:

```swift
func factors(for number: Int) async -> [Int] {
    var result = [Int]()

    for check in 1...number {   
        if number.isMultiple(of: check) {
            result.append(check)
            await Task.yield()                
        }
    }

    return result
}

let factors = await factors(for: 120)
print("Found \(factors.count) factors for 120.")
```

- That offers Swift the chance to pause every time a multiple is found. 

- Yes, it will be called a lot in the first few iterations, but fewer multiples will be found over time and so it probably won’t yield as often as the previous example – it could well defeat the point of using `yield()` in the first place.

- Calling `yield()` does not always mean the task will stop running: if it has a higher priority than other tasks that are waiting, it’s entirely possible your task will just immediately resume its work.

- Think of this as `guidance` – `we’re giving Swift the chance to execute other tasks temporarily rather than forcing it to do so`.

- Think of calling `Task.yield()` as the equivalent of calling a fictional `Task.doNothing()` method – `it gives Swift the chance to adjust the execution of its tasks without actually creating any real work`.


## How to create a task group and add tasks to it

- Swift’s task groups are collections of tasks that work together to produce a single result.

- Each `task` inside the `group` must `return the same kind of data`, but `if you use enum associated values you can make them send back different kinds of data` – it’s a little clumsy, but it works.

- Creating a `task group` is done in a very precise way to avoid us creating problems for ourselves: rather than creating a `TaskGroup` instance directly, we do so by calling the `withTaskGroup(of:)` function and telling it the data type the task group will return.

- We give this function the code for our group to execute, and Swift will pass in the `TaskGroup` that was created, which we can then use to add tasks to the group.

- First, I want to look at the simplest possible example of task groups, which is returning 5 constant strings, adding them into a single array, then joining that array into a string:

```swift
func printMessage() async {
    let string = await withTaskGroup(of: String.self) { group -> String in
        group.addTask { "Hello" }
        group.addTask { "From" }
        group.addTask { "A" }
        group.addTask { "Task" }
        group.addTask { "Group" }

        var collected = [String]()

        for await value in group {
            collected.append(value)
        }

        return collected.joined(separator: " ")
    }

    print(string)
}

await printMessage()
```

- I know it’s trivial, but it demonstrates several important things:

1- We must specify the exact type of data our task group will return, which in our case is `String.self` so that each child task can return a string.

2- We need to specify exactly what the return value of the group will be using `group -> String` in – Swift finds it hard to figure out the return value otherwise.

3- We call `addTask()` once for each task we want to add to the group, passing in the work we want that task to do.

4- Task groups conform to `AsyncSequence`, so we can read all the values from their children using `for await`, or by calling `group.next()` repeatedly.

5- Because the whole `task group` executes asynchronously, we must call it using `await`.

- However, there’s one other thing you can’t see in that code sample, which is that our `task results are sent back in completion order` and `not creation order`.

- That is, our code above might send back `“Hello From A Task Group”`, but it also might send back `“Task From A Hello Group”`, `“Group Task A Hello From”`, or any other possible variation – the return value could be different every time.

- Tasks created using `withTaskGroup()` cannot throw errors. 

- If you want them to be able to throw errors that bubble upwards – i.e., that are handled outside the task group – you should use `withThrowingTaskGroup()` instead.

- To demonstrate this, and also to demonstrate a more real-world example of `TaskGroup` in action, we could write some code that fetches several news feeds and combines them into one list:

```swift
struct NewsStory: Identifiable, Decodable {
    let id: Int
    let title: String
    let strap: String
    let url: URL
}

struct ContentView: View {
    @State private var stories = [NewsStory]()

    var body: some View {
        NavigationView {
            List(stories) { story in
                VStack(alignment: .leading) {
                    Text(story.title)
                        .font(.headline)

                    Text(story.strap)
                }
            }
            .navigationTitle("Latest News")
        }
        .task {
            await loadStories()
        }
    }
    
    func loadStories() async {
        do {
            stories = try await withThrowingTaskGroup(of: [NewsStory].self) { group -> [NewsStory] in
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        let (data, _) = try await URLSession.shared.data(from: url)
                        return try JSONDecoder().decode([NewsStory].self, from: data)
                    }
                }

                let allStories = try await group.reduce(into: [NewsStory]()) { $0 += $1 }
                return allStories.sorted { $0.id > $1.id }
            }
        } catch {
            print("Failed to load stories")
        }
    }
}
```

- In that code you can see we have a simple struct that contains one news story, a SwiftUI view showing all the news stories we fetched, plus a `loadStories()` method that handles fetching and decoding several news feeds into a single array.

- There are four things in there that deserve special attention:

1- Fetching and decoding news items might throw errors, and those errors are not handled inside the tasks, so we need to use `withThrowingTaskGroup()` to create the group.

2- One of the main advantages of `task groups` is being able to add tasks inside a loop – we can loop from 1 through 5 and call `addTask()` repeatedly.

3- Because the task group conforms to `AsyncSequence`, we can call its `reduce()` method to boil all its task results down to a single value, which in this case is a single array of news stories.

4- As I said earlier, `tasks in a group can complete in any order`, so we sorted the resulting array of news stories to get them all in a sensible order.


- Regardless of whether you’re using throwing or non-throwing tasks, all tasks in a group must complete before the group returns. You have three options here:

1- Awaiting all individual tasks in the group.

2- Calling `waitForAll()` will automatically wait for tasks you have not explicitly awaited, discarding any results they return.

3- If you `do not explicitly await any child tasks, they will be implicitly awaited` – Swift will wait for them anyway, even if you aren’t using their return values.

- Of the three, I find myself using the first most often because it’s the most explicit – you aren’t leaving folks wondering why some or all of your tasks are launched then ignored.


## How to cancel a task group

- Swift’s task groups can be cancelled in one of three ways:

1- If the parent task of the task group is cancelled.

2- If you explicitly call `cancelAll()` on the group.

3- If one of your child tasks throws an uncaught error, all remaining tasks will be implicitly cancelled.

- The first of those happens outside of the task group, but the other two are worth investigating.

- First, calling `cancelAll()` will cancel all remaining tasks.

- As with standalone tasks, `cancelling a task group is cooperative`: your child tasks can check for cancellation using `Task.isCancelled` or `Task.checkCancellation()`, but they can ignore cancellation entirely if they want.

- We could write a simple `printMessage()` function like this one, `creating three tasks inside a group in order to generate a string`:

```swift
func printMessage() async {

    let result = await withThrowingTaskGroup(of: String.self) { group -> String in
        group.addTask {
            return "Testing"
        }

        group.addTask {
            return "Group"
        }

        group.addTask {
            return "Cancellation"
        }

        group.cancelAll()
        var collected = [String]()

        do {
            for try await value in group {
                collected.append(value)
            }
        } catch {
            print(error.localizedDescription)
        }

        return collected.joined(separator: " ")
    }

    print(result)
}

await printMessage()
```

- As you can see, that calls `cancelAll()` immediately after creating all three tasks, and yet when the code is run you’ll still see all three strings printed out.

- I’ve said it before, but it bears repeating and this time in bold: `cancelling a task group is cooperative, so unless the tasks you add implicitly or explicitly check for cancellation calling cancelAll() by itself won’t do much`.

- To see `cancelAll()` actually working, try replacing the first `addTask()` call with this:

```swift
group.addTask {
    try Task.checkCancellation()
    return "Testing"
}
```

- And now our behavior will be different: you might see “Cancellation” by itself, “Group” by itself, “Cancellation Group”, “Group Cancellation”, or nothing at all.

- To understand why, keep the following in mind:

1- Swift will start all three tasks immediately. They might all run in parallel; it depends on what the system thinks will work best at runtime.

2- Although we immediately call `cancelAll()`, some of the tasks might have started running.

3- All the tasks finish in completion order, so when we first loop over the group we might receive the result from any of the three tasks.

- When you put those together, it’s entirely possible the first task to complete is the one that calls `Task.checkCancellation()`, which means our loop will exit, we’ll print an error message, and send back an empty string.

- Alternatively, one or both of the other tasks might run first, in which case we’ll get our other possible outputs.

- Remember, calling `cancelAll()` only cancels remaining tasks, `meaning that it won’t undo work that has already completed`.

- Even then the `cancellation is cooperative`, so you need to `make sure the tasks you add to the group check for cancellation`.

- This code attempts to fetch, merge, and display using SwiftUI the contents of five news feeds. 
- If any of the fetches throws an error the whole group will throw an error and end, but if a fetch somehow succeeds while ending up with an empty array it means our data quota has run out and we should stop trying any other feed fetches.

- Here’s the code:

```swift
struct NewsStory: Identifiable, Decodable {
    let id: Int
    let title: String
    let strap: String
    let url: URL
}

struct ContentView: View {
    @State private var stories = [NewsStory]()

    var body: some View {
        NavigationView {
            List(stories) { story in
                VStack(alignment: .leading) {
                    Text(story.title)
                        .font(.headline)

                    Text(story.strap)
                }
            }
            .navigationTitle("Latest News")
        }
        .task {
            await loadStories()
        }
    }
    
    func loadStories() async {
        do {
            try await withThrowingTaskGroup(of: [NewsStory].self) { group -> Void in
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        let (data, _) = try await URLSession.shared.data(from: url)
                        try Task.checkCancellation()
                        return try JSONDecoder().decode([NewsStory].self, from: data)
                    }
                }

                for try await result in group {
                    if result.isEmpty {
                        group.cancelAll()
                    } else {
                        stories.append(contentsOf: result)
                    }
                }

                stories.sort { $0.id < $1.id }
            }
        } catch {
            print("Failed to load stories: \(error.localizedDescription)")
        }
    }
}
```

- As you can see, that calls `cancelAll()` as soon as any feed sends back an empty array, thus aborting all remaining fetches. 
- Inside the child tasks there is an explicit call to `Task.checkCancellation()`, but the `data(from:)` also runs check for cancellation to avoid doing unnecessary work.

- The other way task groups get cancelled is if one of the tasks throws an uncaught error.

- We can write a simple test for this by creating two tasks inside a group, both of which sleep for a little time.

- The `first task will sleep for 1 second then throw an example error`, whereas the `second will sleep for 2 seconds then print the value of Task.isCancelled`.

```swift
enum ExampleError: Error {
    case badURL
}

func testCancellation() async {
    do {
        try await withThrowingTaskGroup(of: Void.self) { group -> Void in
            group.addTask {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                throw ExampleError.badURL
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                print("Task is cancelled: \(Task.isCancelled)")
            }

            try await group.next()
        }
    } catch {
        print("Error thrown: \(error.localizedDescription)")
    }
}

await testCancellation()
```

- Note: Just throwing an error inside `addTask()` isn’t enough to `cause other tasks in the group to be cancelled` – this only happens when you access the value of the throwing task using `next()` or when looping over the child tasks.

- This is why the code sample above specifically waits for the result of a task, because doing so will cause `ExampleError.badURL` to `be rethrown and cancel the other task`.

- Calling `addTask()` on your group will unconditionally add a new task to the group, even if you have already cancelled the group. 

- If you want to avoid adding tasks to a cancelled group, use the `addTaskUnlessCancelled()` method instead – it works identically except `will do nothing if called on a cancelled group`. 

- Calling `addTaskUnlessCancelled()` returns a Boolean that will be true if the task was successfully added, or false if the task group was already cancelled.


## How to handle different result types in a task group

- Each task in a Swift `task group must return the same type of data as all the other tasks in the group`, which is often problematic – what if you need one task group to handle several different types of data?

- In this situation you should consider using `async let` for your concurrency if you can, because every `async let` expression `can return its own unique data type`.

- So, the first might result in an array of strings, the second in an integer, and so on, and once you’ve awaited them all you can use them however you please.

- However, if you need to use task groups – for example if you need to create your tasks in a loop – then there is a solution: 

- `Create an enum with associated values that wrap the underlying data you want to return`.

- Using this approach, `each of the tasks in your group still return a single data type` – `one of the cases from your enum` – but `inside those cases you can place the unique data types you’re actually using`.

- This is best demonstrated with some example code, but because it’s quite a lot I’m going to add inline comments so you can see what’s going on:

```swift
// A struct we can decode from JSON, storing one message from a contact.
struct Message: Decodable {
    let id: Int
    let from: String
    let message: String
}

// A user, containing their name, favorites list, and messages array.
struct User {
    let username: String
    let favorites: Set<Int>
    let messages: [Message]
}

// A single enum we'll be using for our tasks, each containing a different associated value.
enum FetchResult {
    case username(String)
    case favorites(Set<Int>)
    case messages([Message])
}

func loadUser() async {
    // Each of our tasks will return one FetchResult, and the whole group will send back a User.
    let user = await withThrowingTaskGroup(of: FetchResult.self) { group -> User in
        // Fetch our username string
        group.addTask {
            let url = URL(string: "https://hws.dev/username.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = String(decoding: data, as: UTF8.self)

            // Send back FetchResult.username, placing the string inside.
            return .username(result)
        }
        
        // Fetch our favorites set
        group.addTask {
            let url = URL(string: "https://hws.dev/user-favorites.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(Set<Int>.self, from: data)

            // Send back FetchResult.favorites, placing the set inside.
            return .favorites(result)
        }

        // Fetch our messages array
        group.addTask {
            let url = URL(string: "https://hws.dev/user-messages.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode([Message].self, from: data)

            // Send back FetchResult.messages, placing the message array inside
            return .messages(result)
        }
        
        // At this point we've started all our tasks,
        // so now we need to stitch them together into
        // a single User instance. First, we set
        // up some default values:
        var username = "Anonymous"
        var favorites = Set<Int>()
        var messages = [Message]()

        // Now we read out each value, figure out 
        // which case it represents, and copy its
        // associated value into the right variable.
        do {
            for try await value in group {
                switch value {
                case .username(let value):
                    username = value
                case .favorites(let value):
                    favorites = value
                case .messages(let value):
                    messages = value
                }
            }
        } catch {
            // If any of the fetches went wrong, we might
            // at least have partial data we can send back.
            print("Fetch at least partially failed; sending back what we have so far. \(error.localizedDescription)")
        }
        
        // Send back our user, either filled with
        // default values or using the data we
        // fetched from the server.
        return User(username: username, favorites: favorites, messages: messages)
    }

    // Now do something with the finished user data.
    print("User \(user.username) has \(user.messages.count) messages and \(user.favorites.count) favorites.")
}

await loadUser()
```

- I know it’s a lot of code, but really it boils down to two things:

1- `Creating an enum with one case for each type of data you’re expecting`, with `each case having an associated value of that type`.

2- `Reading the results from your group’s tasks using a switch block that reads each case from your enum, extracts the associated value inside, and acts on it appropriately`.

- So, it’s not impossible to handle heterogeneous results in a task group, it just requires a little extra thinking.


## What is the difference between async let tasks and task groups?

- Swift `async let`, `Task`, and `task groups` all solve a similar problem: 

- They allow us to create concurrency in our code so the system is able to run them efficiently. 

- Beyond that, the way they work is quite different, and which you’ll choose depends on your exact scenario.

- To help you understand how they differ, and provide some guidance on where each one is a good idea, I want to walk through the key behaviors of each of them.

- First, `async let` and `Task` are designed to `create specific, individual pieces of work`, whereas `task groups` are designed to `run multiple pieces of work at the same time and gather the results`.

- As a result, `async let` and `Task` have `no way to express a dynamic amount of work that should run in parallel`.

- For example, if you had an array of URLs and wanted to fetch them all in parallel, convert them into arrays of weather readings, then average them to a single Double, `task groups` would be a great choice because you won’t know ahead of time how many URLs are in your array.

- Trying to write this using `async let` or `Task` just wouldn’t work, because you’d have to `hard-code the exact number of async let lines rather than just loop over an array`.

- Second, `task groups` automatically let us process results from child tasks in the order they complete, rather than in an order we specify.

- For example, if we wanted to fetch five pieces of data, `task groups` allow us to use `group.next()` to read whichever of the five comes back first, whereas using `async let` and `Task` would require us to await values in a specific, fixed order.

- That alone is a helpful feature of task groups, but in some situations it goes from helpful to crucial.

- For example, if you have three possible servers for some data and want to use whichever one responds fastest, `task groups` are perfect – you can use `addTask()` once for each server, then call `next()` only once to read whichever one responded fastest.

- Third, although all three forms of concurrency will automatically be marked as cancelled if their parent task is cancelled, only `Task` and `task group` can be cancelled directly, using `cancel()` and `cancelAll()` respectively. There is no equivalent for `async let`.

- Fourth, because `async let` doesn’t give us a handle to the underlying task it creates for us, it’s not possible to pass that task elsewhere – we can’t start an `async let` task in one function then pass that task to a different function.

- On the other hand, if you create a task that returns a string and never throws an error, you can pass that `Task<String, Never>` object around as needed.

- And finally, although `task groups` can work with heterogeneous results – i.e., child tasks that return different types of data – it takes the extra work of making an enum to wrap the data. 

- `async let` and `Task` do not suffer from this problem because they always return a single result type, so each result can be different.

- By sheer volume of advantages you might think that `async let` is clearly much less useful than both `Task` and `task groups`, but not all those points carry equal weight in real-world code. 

- In practice, I would suggest you’re likely to:

1- Use `async let` the most, it `works best when there is a fixed amount of work to do`.

2- Use `Task` for some places where `async let` doesn’t work, such as `passing an incomplete value to a function`.

3- Use `task groups` least commonly, or at least use them directly least commonly – you might build other things on top of them.


- I find that order is pretty accurate in practice, for a number of reasons:

1- I normally want results from all the work I start, so being able to skip some or get results in completion order is less important.

2- It’s surprisingly common to want to work with different data types, which is clumsy with `task groups`.

3- If I need to be able to cancel tasks, `Task` is similar enough to `async let` that it’s easy to move across to `Task` without going all the way to a `task group`.

- I would recommend you start with `async let`, move to `Task` if needed, then go to `task groups` only if there’s something specific they offer that you need.


## How to make async command-line tools and scripts

- If you’re writing a command-line tool, you can use `async` in conjunction with the `@main` attribute to launch your app into an async context immediately. 

- To do this, first create the static `main()` method as you normally would with `@main`, then add `async` to it.

- You can optionally also add `throws` if you don’t intend to handle errors there.

- For example, we could write a small command-line tool that fetches data from a URL and prints it out:

```swift
@main
struct UserFetcher {
    static func main() async throws {
        let url = URL(string: "https://hws.dev/users.csv")!

        for try await line in url.lines {
            print("Received user: \(line)")
        }
    }
}
```

- `Tip:` Just like using the `@main` attribute with a synchronous `main()` method, you should not include a `main.swift` file in your command-line project.

- Using `async` and `@main` together benefits from the full range of Swift concurrency features. 

- Behind the scenes, Swift will automatically create a new task in which it runs your `main()` method, then terminate the program when that task finishes.

- Although it doesn’t work in the current Xcode release, the `goal is for Swift to support async calls in top-level code`. 

- This would mean you could use `main.swift` files and remove most of the code in the previous sample – you could just go ahead and make async calls outside of a function.


## How to create and use task local values

- Swift lets us attach metadata to a task using task-local values, which are small pieces of information that any code inside a task can read.

- We already seen how we can read `Task.isCancelled` to see whether the current task is cancelled or not, but that’s not a true static property – `it’s scoped to the current task, rather than shared across all tasks`.

- This is the power of task-local values: `the ability to create static-like properties inside a task`.

- `Important`: Most people will not want to use task-local values – if you’re just curious you’re welcome to read on and explore how task-local values work, but honestly they are useful in only a handful of very specific circumstances and if you find them complex I wouldn’t worry too much.

- Task-local values are analogous to thread-local values in an old-style multithreading environment: `we attach some metadata to our task, and any code running inside that task can read that data as needed`.

- Swift’s implementation is carefully scoped so that you create contexts where the data is available, rather than just injecting it directly into the task, which makes it possible to adjust your metadata over time.

- However, `inside that context all code is able to read your task-local values`, regardless of how it’s used.

- Using task-local values happens in four steps:

1- Creating a type that has one or more properties we want to make into task-local values. This can be an enum, struct, class, or even actor if you want, but I’d suggest starting with an enum so it’s clear you don’t intend to make instances of the type.

2- Marking each of your task-local values with the `@TaskLocal` property wrapper. These properties can be any type you want, including optionals, but must be marked as `static`.

3- Starting a new task-local scope using `YourType.$yourProperty.withValue(someValue) { … }`.

4- Inside the task-local scope, any time you read `YourType.yourProperty` you will receive the task-local value for that property – it’s not a regular static property that has a single value shared between all parts of your program, but instead it can return a different value depending on which task tries to read it.

- First, our simple example. This will create a `User` enum with a `id` property that is marked `@TaskLocal`, then it will launch a couple of tasks with different values for that user ID. 

- Each task will do exactly the same thing: `print the user ID, sleep for a small amount of time, then print the user ID again`, which `will allow you to see both tasks running at the same time while having their own unique task-local user ID`.

```swift
enum User {
    @TaskLocal static var id = "Anonymous"
}

@main
struct App {
    static func main() async throws {
        Task {
            try await User.$id.withValue("Piper") {
                print("Start of task: \(User.id)")
                try await Task.sleep(nanoseconds: 1_000_000)
                print("End of task: \(User.id)")
            }
        }

        Task {
            try await User.$id.withValue("Alex") {
                print("Start of task: \(User.id)")
                try await Task.sleep(nanoseconds: 1_000_000)
                print("End of task: \(User.id)")
            }
        }

        print("Outside of tasks: \(User.id)")
    }
}
```

```
When that code runs it will print:

Start of task: Alex
Start of task: Piper
Outside of tasks: Anonymous
End of task: Alex
End of task: Piper
```

- Of course, because the two tasks run independently of each other you might also find that the order of Piper and Alex switch. 

- The important thing is that each task has its own value for `User.id` even as they overlap, and code outside the task will continue to use the original value.

- As you can see, Swift makes it impossible to forget about a task-local value you’ve set, because it only exists for the work inside `withValue()`.

- This scoping approach also means it’s possible to nest multiple task locals as needed, and you can even shadow task locals – start a scope for one, do some work, then start another nested scope for that same property. so that it temporarily has a different value.

- In real-world code, task-local values are useful for places where you need to repeatedly pass values around inside your tasks – values that need to be shared within the task, but not across your whole program like a singleton might be. 


- As a more complex example, we could create a simple `Logger` struct that writes out messages depending on the current level of logging: `debug` being the lowest log level, then `info`, `warn`, `error`, and finally `fatal` at the highest level. 

- If we make the log level – which messages to print – be a task-local value, then each of our tasks can have whatever level of logging they want, regardless of what other tasks are doing.

- To make this work we need three things:

1- An enum to describe the five levels of logging.

2- A `Logger` struct that is a singleton.

3- A `task-local` property inside `Logger` to store the current log level. `(Even though the logger is a singleton, the log level is task-local.)`

- On top of that, we need a couple more things to actually demonstrate the logger in action: a `fetch()` method that downloads data from a URL and creates various logging messages, and a couple of tasks that call `fetch()` with different task-local log settings so we can see exactly how it all works.

```swift
// Our five log levels, marked Comparable so we can use < and > with them.
enum LogLevel: Comparable {
    case debug, info, warn, error, fatal
}

struct Logger {

    // The log level for an individual task
    @TaskLocal static var logLevel = LogLevel.info

    // Make this struct a singleton
    private init() { }
    static let shared = Logger()

    // Print out a message only if it meets or exceeds our log level.
    func write(_ message: String, level: LogLevel) {
        if level >= Logger.logLevel {
            print(message)
        }
    }
}

@main
struct App {

    // Returns data from a URL, writing log messages along the way.
    static func fetch(url urlString: String) async throws -> String? {
        Logger.shared.write("Preparing request: \(urlString)", level: .debug)

        if let url = URL(string: urlString) {
            let (data, _) = try await URLSession.shared.data(from: url)
            Logger.shared.write("Received \(data.count) bytes", level: .info)
            return String(decoding: data, as: UTF8.self)
        } else {
            Logger.shared.write("URL \(urlString) is invalid", level: .error)
            return nil
        }
    }

    // Starts a couple of fire-and-forget tasks with different log levels.
    static func main() async throws {
        Task {
            try await Logger.$logLevel.withValue(.debug) {
                try await fetch(url: "https://hws.dev/news-1.json")
            }
        }

        Task {
            try await Logger.$logLevel.withValue(.error) {
                try await fetch(url: "https:\\hws.dev/news-1.json")
            }
        }
    }
}
```

- When that runs you’ll see `“Preparing request: https://hws.dev/news-1.json”` as the first task starts, then `“URL https:\hws.dev/news-1.json is invalid”` as the second task starts (I used a back slash rather than forward slash), then `“Received 8075 bytes”` as the first task finishes downloading its data.

- So, here our `fetch()` method doesn’t even need to know that a task-local value is being used – it just calls the `Logger` singleton, which in turn refers to the task-local value.

- To finish up, I want to leave you with a few important tips for using task-local values:

1- It’s okay to access a task-local value outside of a `withValue()` scope – `you’ll just get back whatever default value you gave it.` 

2- Although regular tasks inherit task-local values of their parent task, detached tasks do not because they don’t have a parent.

3- Task-local values `are read-only`; you can only modify them by calling `withValue()` as shown above.


- Put more plainly, if task locals are the answer, there’s a very good chance you’re asking the wrong question.


## How to run tasks using SwiftUI task modifier

- SwiftUI provides a `task()` modifier that starts a new detached task as soon as a view appears, and automatically cancels the task when the view disappears.

- This is sort of the equivalent of starting a task in `onAppear()` then cancelling it `onDisappear()`, although `task()` has an extra ability to track an identifier and restart its task when the identifier changes.

- In the simplest scenario – and probably the one you’re going to use the most – `task()` is the best way to load your view’s initial data, which might be loaded from local storage or by fetching and decoding a remote URL.

- For example, this downloads data from a server and decodes it into an array for display in a list:

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let text: String
}

struct ContentView: View {
    @State private var messages = [Message]()

    var body: some View {
        NavigationView {
            List(messages) { message in
                VStack(alignment: .leading) {
                    Text(message.from)
                        .font(.headline)

                    Text(message.text)
                }
            }
            .navigationTitle("Inbox")
            .task {
                await loadMessages()
            }
        }
    }

    func loadMessages() async {
        do {
            let url = URL(string: "https://hws.dev/messages.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(id: 0, from: "Failed to load inbox.", text: "Please try again later.")
            ]
        }
    }
}
```

- Important: The `task()` modifier is a great place to load the data for your SwiftUI views.

- Remember, they can be recreated many times over the lifetime of your app, so you should avoid putting this kind of work into their initializers if possible.

- A more advanced usage of `task()` is to attach some kind of `Equatable` identifying value – when that value changes SwiftUI will automatically cancel the previous task and create a new task with the new value.

- This might be some shared app state, such as whether the user is logged in or not, or some local state, such as what kind of filter to apply to some data.

- As an example, we could upgrade our messaging view to support both an `Inbox` and a `Sent` box, both fetched and decoded using the same `task()` modifier.

- By setting the message box type as the identifier for the task with `.task(id: selectedBox)`, SwiftUI will automatically update its message list every time the selection changes.

- Here’s how that looks in code:

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let user: String
    let text: String
}

// Our content view is able to handle two kinds of message box now.
struct ContentView: View {
    @State private var messages = [Message]()
    @State private var selectedBox = "Inbox"
    let messageBoxes = ["Inbox", "Sent"]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(messages) { message in
                        VStack(alignment: .leading) {
                            Text(message.user)
                                .font(.headline)

                            Text(message.text)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(selectedBox)

            // Our task modifier will recreate its fetchData() task whenever selectedBox changes
            .task(id: selectedBox) {
                await fetchData()
            }
            .toolbar {
                // Switch between our two message boxes
                Picker("Select a message box", selection: $selectedBox) {
                    ForEach(messageBoxes, id: \.self, content: Text.init)
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
     // This is almost the same as before, but now loads the selectedBox JSON file rather than always loading the inbox.
    func fetchData() async {
        do {
            let url = URL(string: "https://hws.dev/\(selectedBox.lowercased()).json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(id: 0, user: "Failed to load message box.", text: "Please try again later.")
            ]
        }
    }
}
```

- Tip: That example uses the `shared URLSession`, which means it will cache its responses and so load the two inboxes only once.

- If that’s what you want you’re all set, but if you want it to always fetch the files make sure you create your own session configuration and disable caching.

- One particularly interesting use case for `task()` is with `AsyncSequence` collections that continuously generate values.

- This might be a server that maintains an open connection while sending fresh content, it might be the `URLWatcher` example we looked at previously, or perhaps just a local value.

- For example, we could write a simple random number generator that regularly emits new random numbers – with the `task()` modifier we can constantly watch that for changes, and stream the results into a SwiftUI view.

- To bring this example to life, we’re going to add one more thing: the random number generator will print a message every time a number is generated, and the resulting number list will be shown inside a detail view.

- Both of these are done so you can see how `task()` automatically cancels its work: the numbers will automatically start streaming when the detail view is shown, and stop streaming when the view is dismissed.

```swift
// A simple random number generator sequence
struct NumberGenerator: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Int
    let delay: Double
    let range: ClosedRange<Int>

    init(in range: ClosedRange<Int>, delay: Double = 1) {
        self.range = range
        self.delay = delay
    }

    mutating func next() async -> Int? {
        // Make sure we stop emitting numbers when our task is cancelled
        while Task.isCancelled == false {
            try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            print("Generating number")
            return Int.random(in: range)
        }

        return nil
    }

    func makeAsyncIterator() -> NumberGenerator {
        self
    }
}

// This exists solely to show DetailView when requested.
struct ContentView: View {
    var body: some View {
        NavigationView {
            NavigationLink(destination: DetailView()) {
                Text("Start Generating Numbers")
            }
        }
    }
}

// This generates and displays all the random numbers we've generated.
struct DetailView: View {
    @State private var numbers = [String]()
    let generator = NumberGenerator(in: 1...100)

    var body: some View {
        List(numbers, id: \.self, rowContent: Text.init)
            .task {
                await generateNumbers()
            }
    }

    func generateNumbers() async {
        for await number in generator {
            numbers.insert("\(numbers.count + 1). \(number)", at: 0)
        }
    }
}
```

- Notice how the `generateNumbers()` method at the end doesn’t actually have any way of exiting? 

- That’s because it will exit automatically when `generator` stops returning values, which will happen when the task is cancelled, and that will happen when `DetailView` is dismissed – it takes no special work from us.

- Tip: The `task()` modifier accepts a `priority` parameter if you want fine-grained control over your task’s priority. 

- For example, use `.task(priority: .low)` to create a low-priority task.


## Is it efficient to create many tasks

- Previously we talked about the concept of `thread explosion`, which is `when you create many more threads than CPU cores and the system struggles to manage them effectively`.

- However, Swift’s `tasks are implemented very differently from threads`, and so are significantly less likely to cause performance problems when used in large numbers. 

- In fact one of the Swift team who worked on it said that unless you’re creating over 10,000 tasks it’s not worth worrying about the impact of so many tasks.

- That doesn’t mean creating so many tasks is necessarily the best idea.

- You might think that’s hard to do, but a task group calling `addTask()` inside a loop might create several hundred or even several thousand depending on what you were looping over.

- And that’s okay. Again, even if you’re creating well over 10,000 tasks it’s not likely to cause a problem as long as you know that’s what you’re doing – if that’s the architectural choice you’re making after evaluating the alternative.

- So, broadly speaking you should feel free to create as many tasks as you want, but if you ever find yourself creating tasks to transform elements inside huge arrays you might want to double-check your performance using something like Instruments.
