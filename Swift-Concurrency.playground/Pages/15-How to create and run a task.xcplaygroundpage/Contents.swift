import Foundation
import UIKit
import SwiftUI
import PlaygroundSupport

// MARK: - Create Task and store the return value -

//struct NewsItem: Decodable {
//    let id: Int
//    let title: String
//    let url: URL
//}
//
//struct HighScore: Decodable {
//    let name: String
//    let score: Int
//}
//
//func fetchUpdates() async {
//
//    let newsTask = Task { () -> [NewsItem] in
//        let url = URL(string: "https://hws.dev/headlines.json")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return try JSONDecoder().decode([NewsItem].self, from: data)
//    }
//
//    let highScoreTask = Task { () -> [HighScore] in
//        let url = URL(string: "https://hws.dev/scores.json")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return try JSONDecoder().decode([HighScore].self, from: data)
//    }
//
//    do {
//        let news = try await newsTask.value
//        let highScores = try await highScoreTask.value
//
//        print("Latest news loaded with \(news.count) items.")
//
//        if let topScore = highScores.first {
//            print("\(topScore.name) has the highest score with \(topScore.score), out of \(highScores.count) total results.")
//        }
//    } catch {
//        print("There was an error loading user data.")
//    }
//}
//
//Task {
//  await fetchUpdates()
//}


// MARK: - Create Task and execute async function -

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


PlaygroundPage.current.setLiveView(ContentView())
