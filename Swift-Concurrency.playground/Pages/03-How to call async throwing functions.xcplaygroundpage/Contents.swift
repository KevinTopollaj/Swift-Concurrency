//: [Previous](@previous)

import Foundation
import UIKit


func fetchFavorites() async throws -> [Int] {
  let url = URL(string: "https://hws.dev/user-favorites.json")!
  let (data, _) = try await URLSession.shared.data(from: url)
  return try JSONDecoder().decode([Int].self, from: data)
}


Task {
  if let favorites = try? await fetchFavorites() {
    print("Fetched \(favorites.count) favorites.")
  } else {
    print("Failed to fetch favorites.")
  }
}


//: [Next](@next)
