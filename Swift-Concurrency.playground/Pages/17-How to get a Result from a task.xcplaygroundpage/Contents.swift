import Foundation
import UIKit

enum LoadError: Error {
  case fetchFailed, decodeFailed
}

func fetchQuotes() async {
  
  let downloadTask = Task { () -> String in
    
    let url = URL(string: "https://hws.dev/quotes.txt")!
    let data: Data
    
    do {
      (data, _) = try await URLSession.shared.data(from: url)
    } catch {
      throw LoadError.fetchFailed
    }
    
    if let string = String(data: data, encoding: .utf8) {
      return string
    } else {
      throw LoadError.decodeFailed
    }
    
  }
  
  let result = await downloadTask.result
  
  do {
    let string = try result.get()
    print(string)
  } catch LoadError.fetchFailed {
    print("Unable to fetch the quotes")
  } catch LoadError.decodeFailed {
    print("Unable to decode quotes to text")
  } catch {
    print("Unknown error")
  }
  
}

//Task {
//  await fetchQuotes()
//}


// If you don’t care what errors are thrown, or don’t mind digging through Foundation’s various errors yourself, you can avoid handling errors in the task and just let them propagate up:

func fetchQuotess() async {
  
  let downloadTask = Task { () -> String in
    
    let url = URL(string: "https://hws.dev/quotes.txt")!
    let (data,_) = try await URLSession.shared.data(from: url)
    return String(decoding: data, as: UTF8.self)
  }
  
  let result = await downloadTask.result
  
  do {
    let string = try result.get()
    print(string)
  } catch {
    print("Unknown error: \(error)")
  }
}

Task {
  await fetchQuotess()
}
