//: [Previous](@previous)

import Foundation
import UIKit

struct Message: Codable, Identifiable {
  let id: Int
  let from: String
  let message: String
}

func fetchMessages(completion: @escaping ([Message]) -> Void) {
  let url = URL(string: "https://hws.dev/user-messages.json")!
  
  URLSession.shared.dataTask(with: url) { data, response, error in
    if let data = data {
      if let message = try? JSONDecoder().decode([Message].self, from: data) {
        completion(message)
        return
      }
    }
    completion([])
  }.resume()
}

func fetchMessages() async -> [Message] {
  await withCheckedContinuation { continuation in
    fetchMessages { messages in
      continuation.resume(returning: messages)
    }
  }
}

Task {
  let messages = await fetchMessages()
  
  print("Downloaded \(messages.count) messages.")
}




//: [Next](@next)
