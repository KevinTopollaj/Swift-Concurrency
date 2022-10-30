import UIKit

struct Message: Decodable {
  let id: Int
  let from: String
  let message: String
}

struct User: Decodable {
  let username: String
  let favorites: Set<Int>
  let messages: [Message]
}

// A single enum we'll be using for our tasks, each containing a different associated value.
enum FetchResult {
  case username(String)
  case favorites(Set<Int>)
  case messages([Message])
}

func loadUser() async {
  // Each of our tasks will return one FetchResult, and the whole group will send back a User.
  let user = await withThrowingTaskGroup(of: FetchResult.self) { group -> User in
    
    // Fetch the user name string
    group.addTask {
      let url = URL(string: "https://hws.dev/username.json")!
      let (data, _) = try await URLSession.shared.data(from: url)
      let result = String(decoding: data, as: UTF8.self)
      
      // Send back FetchResult.username, placing the string inside.
      return .username(result)
    }
    
    // Fetch our favorites set
    group.addTask {
      let url = URL(string: "https://hws.dev/user-favorites.json")!
      let (data, _) = try await URLSession.shared.data(from: url)
      let result = try JSONDecoder().decode(Set<Int>.self, from: data)
      
      // Send back FetchResult.favorites, placing the set inside.
      return .favorites(result)
    }
    
    // Fetch our messages array
    group.addTask {
      let url = URL(string: "https://hws.dev/user-messages.json")!
      let (data, _) = try await URLSession.shared.data(from: url)
      let result = try JSONDecoder().decode([Message].self, from: data)
      
      // Send back FetchResult.messages, placing the message array inside
      return .messages(result)
    }
    
    // At this point we've started all our tasks, so now we need to stitch them together into a single User instance.
    // First, we set up some default values:
    var username = "Anonymous"
    var favorites = Set<Int>()
    var messages = [Message]()
    
    // Now we read out each value, figure out which case it represents, and copy its associated value into the right variable.
    do {
      for try await value in group {
        switch value {
          case .username(let value):
            username = value
          case .favorites(let value):
            favorites = value
          case .messages(let value):
            messages = value
        }
      }
    } catch {
      // If any of the fetches went wrong, we might at least have partial data we can send back.
      print("Fetch at least partially failed; sending back what we have so far. \(error.localizedDescription)")
    }
    
    // Send back our user, either filled with default values or using the data we fetched from the server.
    return User(username: username, favorites: favorites, messages: messages)
  }
  
  // Now do something with the finished user data.
  print("User \(user.username) has \(user.messages.count) messages and \(user.favorites.count) favorites.")
}

Task {
  await loadUser()
}

