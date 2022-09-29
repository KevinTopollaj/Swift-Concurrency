import UIKit
import Foundation

// Synchronous function that rolls a virtual dice and returns its result:

func randomD6() -> Int {
  Int.random(in: 1...6)
}

let result = randomD6()
print(result)

// Asynchronous or async function that rolls a virtual dice and returns its result:
func asyncRandomD6() async -> Int {
  Int.random(in: 1...6)
}

Task {
  let asyncResult = await asyncRandomD6()
  print(asyncResult)
}


//
func fetchNews() async -> Data? {
    do {
        let url = URL(string: "https://hws.dev/news-1.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    } catch {
        print("Failed to fetch data")
        return nil
    }
}

Task {
  if let data = await fetchNews() {
      print("Downloaded \(data.count) bytes")
  } else {
      print("Download failed.")
  }
}

