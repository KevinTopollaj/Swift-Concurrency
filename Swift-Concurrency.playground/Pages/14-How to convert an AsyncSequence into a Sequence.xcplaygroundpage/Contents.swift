//: [Previous](@previous)

import Foundation
import UIKit

extension AsyncSequence {
  
  func collect() async rethrows -> [Element] {
    
    try await reduce(into: [Element]()) { $0.append($1) }
    
  }
}

// With that in place, you can now call collect() on any async sequence in order to get a simple array of its values.

func getNumberArray() async throws -> [Int] {
  
  let url = URL(string: "https://hws.dev/random-numbers.txt")!
  let numbers = url.lines.compactMap(Int.init)
  return try await numbers.collect()
}


Task {
  if let numbers = try? await getNumberArray() {
    for number in numbers {
      print(number)
    }
  }
}


