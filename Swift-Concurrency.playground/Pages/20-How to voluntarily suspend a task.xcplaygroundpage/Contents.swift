import Foundation
import UIKit

// you could try yielding only when a multiple is actually found, like this:


func factors(for number: Int) async -> [Int] {
  var result = [Int]()
  
  for check in 1...number {
    if number.isMultiple(of: check) {
      result.append(check)
      await Task.yield()
    }
  }
  
  return result
}

Task {
  let factors = await factors(for: 120)
  print("Found \(factors.count) factors for 120.")
}
