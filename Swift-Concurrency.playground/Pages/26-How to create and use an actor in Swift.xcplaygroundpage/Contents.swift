import UIKit

/// a URL cache that remembers the data for each URL it downloads. Here’s how that would be created and used:

actor URLCache {
  private var cache = [URL: Data]()
  
  func data(for url: URL) async throws -> Data {
    if let cached = cache[url] {
      return cached
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    cache[url] = data
    return data
  }
}

func printStringData() async throws {
  let cache = URLCache()
  
  let url = URL(string: "https://apple.com")!
  let apple = try await cache.data(for: url)
  let dataString = String(decoding: apple, as: UTF8.self)
  print(dataString)
}

//Task {
//  do {
//    try await printStringData()
//  } catch {
//    print("error: \(error.localizedDescription)")
//  }
//
//}

// Using actor BankAccount and, also using async and await because we can’t directly call deposit() on the other bank account, instead we need to post the request as a message to be executed later.

actor BankAccount {
  
  var balance: Decimal
  
  init(initialBalance: Decimal) {
    balance = initialBalance
  }
  
  func depozit(amount: Decimal) {
    balance = balance + amount
  }
  
  func transfer(amount: Decimal, to other: BankAccount) async {
    // Check that we have enought money to pay
    guard balance > amount else { return }
    
    // Substract it from our balance
    balance = balance - amount
    
    // Send it to the other account
    await other.depozit(amount: amount)
  }
  
}

let firstAccount = BankAccount(initialBalance: 500)
let secondAccount = BankAccount(initialBalance: 200)

Task {
  await firstAccount.transfer(amount: 400, to: secondAccount)
  let a = await firstAccount.balance
  let b = await secondAccount.balance
  print(a)
  print(b)
}
