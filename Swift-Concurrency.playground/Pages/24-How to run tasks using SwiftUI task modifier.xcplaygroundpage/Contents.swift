import UIKit
import SwiftUI
import PlaygroundSupport

//struct Message: Decodable, Identifiable {
//  let id: Int
//  let from: String
//  let text: String
//}

//struct ContentView: View {
//  @State private var messages = [Message]()
//
//  var body: some View {
//    NavigationView {
//      List(messages) { message in
//        VStack(alignment: .leading) {
//          Text(message.from)
//            .font(.headline)
//
//          Text(message.text)
//        }
//      }
//      .navigationTitle("Inbox")
//      .task {
//        await loadMessages()
//      }
//    }
//  }
//
//  func loadMessages() async {
//    do {
//      let url = URL(string: "https://hws.dev/messages.json")!
//      let (data, _) = try await URLSession.shared.data(from: url)
//      messages = try JSONDecoder().decode([Message].self, from: data)
//    } catch {
//      messages = [
//        Message(id: 0, from: "Failed to load inbox.", text: "Please try again later.")
//      ]
//    }
//  }
//
//}



// A more advanced usage of task() is to attach some kind of Equatable identifying value – when that value changes SwiftUI will automatically cancel the previous task and create a new task with the new value.

// As an example, we could upgrade our messaging view to support both an Inbox and a Sent box, both fetched and decoded using the same task() modifier.

// By setting the message box type as the identifier for the task with .task(id: selectedBox), SwiftUI will automatically update its message list every time the selection changes.

//struct Message: Decodable, Identifiable {
//  let id: Int
//  let user: String
//  let text: String
//}
//
//struct ContentView: View {
//
//  @State private var messages = [Message]()
//  @State private var selectedBox = "Inbox"
//  let messageBoxes = ["Inbox", "Sent"]
//
//  var body: some View {
//    NavigationView {
//      List {
//        Section {
//          ForEach(messages) { message in
//            VStack(alignment: .leading) {
//              Text(message.user)
//                .font(.headline)
//
//              Text(message.text)
//            }
//          }
//        }
//      }
//      .listStyle(.insetGrouped)
//      .navigationTitle(selectedBox)
//
//      .task(id: selectedBox) {
//        await fetchData()
//      }
//
//      .toolbar {
//        Picker("Select a message box", selection: $selectedBox) {
//          ForEach(messageBoxes, id: \.self, content: Text.init)
//        }
//        .pickerStyle(.segmented)
//      }
//
//    }
//  }
//
//  func fetchData() async {
//    do {
//      let url = URL(string: "https://hws.dev/\(selectedBox.lowercased()).json")!
//      let (data, _) = try await URLSession.shared.data(from: url)
//      messages = try JSONDecoder().decode([Message].self, from: data)
//    } catch {
//      messages = [
//        Message(id: 0,
//                user: "Failed to load message box.",
//                text: "Please try again later.")
//      ]
//    }
//  }
//
//}



// For example, we could write a simple random number generator that regularly emits new random numbers – with the task() modifier we can constantly watch that for changes, and stream the results into a SwiftUI view.

// the random number generator will print a message every time a number is generated, and the resulting number list will be shown inside a detail view.

// Both of these are done so you can see how task() automatically cancels its work: the numbers will automatically start streaming when the detail view is shown, and stop streaming when the view is dismissed


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


PlaygroundPage.current.setLiveView(ContentView())
