import Foundation
import UIKit
import SwiftUI
import PlaygroundSupport

// example of task groups, which is returning 5 constant strings, adding them into a single array, then joining that array into a string:

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

//Task {
//  await printMessage()
//}


// To demonstrate this, and also to demonstrate a more real-world example of TaskGroup in action, we could write some code that fetches several news feeds and combines them into one list:


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
      print("Failed to get NewsStories")
    }
  }
  
}
PlaygroundPage.current.setLiveView(ContentView())
