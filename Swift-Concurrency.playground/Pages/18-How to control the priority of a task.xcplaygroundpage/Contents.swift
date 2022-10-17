import Foundation
import UIKit

import SwiftUI
import PlaygroundSupport

//Creating a task with a priority look like this:

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

//Task {
//  await fetchQuotes()
//}


// we could build a simple SwiftUI app using a single task, and we don’t need to provide a specific priority –it will automatically run as high priority because it was started from our UI:

struct ContentView: View {
  
  @State private var jokeText = ""
  
  var body: some View {
    VStack {
      Text(jokeText)
      Button("Fetch new joke", action: fetchJoke)
    }
    .frame(width: 300, height: 300)
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


PlaygroundPage.current.setLiveView(ContentView())
