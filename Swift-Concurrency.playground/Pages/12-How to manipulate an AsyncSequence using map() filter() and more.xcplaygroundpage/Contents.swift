import Foundation
import UIKit


// map over the lines from a URL to make each line uppercase, like this:

func shoutQuotes() async throws {
  let url = URL(string: "https://hws.dev/quotes.txt")!
  
  let uppercaseLines = url.lines.map(\.localizedUppercase)
  
  for try await line in uppercaseLines {
    print(line)
  }
}

//Task {
//  try? await shoutQuotes()
//}


// converting between types using map()
struct Quote {
  let text: String
}


func printQuotes() async throws {
  let url = URL(string: "https://hws.dev/quotes.txt")!
  
  let quotes = url.lines.map(Quote.init)
  
  for try await quote in quotes {
    print(quote.text)
  }
}

//Task {
//  try? await printQuotes()
//}


// we could use filter() to check every line with a predicate, and process only those that pass.
func printAnonymousQuotes() async throws {
  
  let url = URL(string: "https://hws.dev/quotes.txt")!
  
  let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
  
  for try await quote in anonymousQuotes {
    print(quote)
  }
}

//Task {
//  try? await printAnonymousQuotes()
//}


// we could use prefix() to read just the first five values from an async sequence:

func printTopQuotes() async throws {
  
  let url = URL(string: "https://hws.dev/quotes.txt")!
  
  let topQuotes = url.lines.prefix(5)
  
  for try await quote in topQuotes {
    print(quote)
  }
  
}


//Task {
//  try? await printTopQuotes()
//}


// For example, this will filter for anonymous quotes, pick out the first five, then make them uppercase:

func customQuotes() async throws {
  
  let url = URL(string: "https://hws.dev/quotes.txt")!
  
  let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
  let topAnonymousQuotes = anonymousQuotes.prefix(5)
  let shoutingTopAnonymousQuotes = topAnonymousQuotes.map(\.localizedUppercase)
  
  for try await line in shoutingTopAnonymousQuotes {
    print(line)
  }
}


//Task {
//  try? await customQuotes()
//}


// When you stack multiple transformations together – for example, a filter, then a prefix, then a map– this will inevitably produce a fairly complex return type, so if you intend to send back one of the complex async sequences you should consider an opaque return type like this:

func getQuotes() async -> some AsyncSequence {

    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
    
    let topAnonymousQuotes = anonymousQuotes.prefix(5)
    
    let shoutingTopAnonymousQuotes = topAnonymousQuotes.map(\.localizedUppercase)
    
    return shoutingTopAnonymousQuotes
}

//Task {
//  let result = await getQuotes()
//
//  do {
//      for try await quote in result {
//          print(quote)
//      }
//  } catch {
//      print("Error fetching quotes")
//  }
//}


// allSatisfy() will check whether all elements in an async sequence pass a predicate of your choosing:

func checkQuotes() async throws {
    
    let url = URL(string: "https://hws.dev/quotes.txt")!
    
    let noShortQuotes = try await url.lines.allSatisfy { $0.count > 30 }
    
    print(noShortQuotes)
}


//Task {
//  try? await checkQuotes()
//}


// You can of course combine methods that create new async sequences and return a single value, for example to fetch lots of random numbers, convert them to integers, then find the largest:

func printHighestNumber() async throws {

    let url = URL(string: "https://hws.dev/random-numbers.txt")!

    if let highest = try await url.lines.compactMap(Int.init).max() {
        print("Highest number: \(highest)")
    } else {
        print("No number was the highest.")
    }
}


//Task {
//  try? await printHighestNumber()
//}


// Or to sum all the numbers:

func sumRandomNumbers() async throws {

    let url = URL(string: "https://hws.dev/random-numbers.txt")!
    
    let sum = try await url.lines.compactMap(Int.init).reduce(0, +)
    
    print("Sum of numbers: \(sum)")
}

Task {
  try? await sumRandomNumbers()
}

