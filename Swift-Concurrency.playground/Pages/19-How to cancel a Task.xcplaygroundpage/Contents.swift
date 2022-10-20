import Foundation
import UIKit

// here’s a function that uses a task to fetch some data from a URL, decodes it into an array, then returns the average:
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

Task {
  await getAverageTemperature()
}


// So, we could upgrade our task to explicitly check for cancellation after the network request, using Task.checkCancellation().

// This is a static function call because it will always apply to whatever task it’s called inside, and it needs to be called using try so that it can throw a CancellationError if the task has been cancelled.

// As you can see, it just takes one call to Task.checkCancellation() to make sure our task isn’t wasting time calculating data that’s no longer needed.

func getAverageTemperature2() async {

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

Task {
  await getAverageTemperature2()
}

// If you want to handle cancellation yourself – if you need to clean up some resources or perform some other calculations, for example – then instead of calling Task.checkCancellation() you should check the value of Task.isCancelled instead.

// To demonstrate this, we could rewrite our function a third time so that cancelling the task or failing to fetch data returns an average temperature of 0.

// This time we’re going to cancel the task ourselves as soon as it’s created, but because we’re always returning a default value we no longer need to handle errors when reading the task’s result:

func getAverageTemperature3() async {

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

Task {
  await getAverageTemperature3()
}

// Now we have one implicit cancellation point with the data(from:) call, and an explicit one with the check on Task.isCancelled.
// If either one is triggered, the task will return 0 rather than throw an error.
