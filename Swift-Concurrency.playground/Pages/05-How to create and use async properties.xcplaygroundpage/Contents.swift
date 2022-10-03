//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport


// Create a URLSession instance that never uses caches

extension URLSession {
  
  static let noCacheSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    return URLSession(configuration: config)
  }()
  
}


// Our struct that will fetch and decode a URL every time we read its `contents` property

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

struct Message: Decodable, Identifiable {
  let id: Int
  let user: String
  let text: String
}

struct ContentView: View {
  
  let source = RemoteFile(url: URL(string: "https://hws.dev/inbox.json")!, type: [Message].self)
  @State private var messages = [Message]()
  
  var body: some View {
    NavigationView {
      List(messages) { message in
        VStack(alignment: .leading) {
          Text(message.user)
            .font(.headline)
          Text(message.text)
        }
      }
      .navigationTitle("Inbox")
      .toolbar {
        Button(action: refresh) {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
      }
      .onAppear(perform: refresh)
    }
  }
  
  func refresh() {
    Task {
      do {
        // Access the property asynchronously
        messages = try await source.contents
      } catch {
        print("Message update failed.")
      }
    }
  }
  
  
}


PlaygroundPage.current.setLiveView(ContentView())

//: [Next](@next)
