import Foundation
import UIKit
import SwiftUI
import PlaygroundSupport

func printMessage() async {
  
  let result = await withThrowingTaskGroup(of: String.self) { group -> String in
    
    group.addTask {
      //      try Task.checkCancellation()
      return "Testing"
    }
    
    group.addTask {
      return "Group"
    }
    
    group.addTask {
      return "Cancelation"
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

//Task {
//  await printMessage()
//}

// If any of the fetches throws an error the whole group will throw an error and end, but if a fetch somehow succeeds while ending up with an empty array it means our data quota has run out and we should stop trying any other feed fetches.

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
      
      try await withThrowingTaskGroup(of: [NewsStory].self) { group in
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
      print("Failed to load stories")
    }
    
  }
  
}


//PlaygroundPage.current.setLiveView(ContentView())


// The other way task groups get cancelled is if one of the tasks throws an uncaught error.

// The first task will sleep for 1 second then throw an example error, whereas the second will sleep for 2 seconds then print the value of Task.isCancelled.

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

Task {
  await testCancellation()
}

