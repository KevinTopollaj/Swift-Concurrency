//: [Previous](@previous)

import UIKit
import Foundation

struct User: Decodable {
  let id: UUID
  let name: String
  let age: Int
}

struct Message: Decodable, Identifiable {
  let id: Int
  let from: String
  let message: String
}

func loadData() async {
  
  async let (userData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-24601.json")!)
  async let (messageData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-messages.json")!)
  
  do {
    let decoder = JSONDecoder()
    
    let user = try await decoder.decode(User.self, from: userData)
    let messages = try await decoder.decode([Message].self, from: messageData)
    
    print("User \(user.name) has \(messages.count) message(s).")
    
  } catch {
    print("Sorry, there was a network problem.")
  }
  
}

Task {
  await loadData()
}

//: [Next](@next)
