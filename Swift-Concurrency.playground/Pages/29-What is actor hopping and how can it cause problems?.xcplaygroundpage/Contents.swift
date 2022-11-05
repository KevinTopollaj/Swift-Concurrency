import UIKit
import SwiftUI
import PlaygroundSupport


struct User: Identifiable {
  let id: Int
}

actor DataBase {
  func loadUsers(ids: [Int]) -> [User] {
    // complex work to load users from the database
    // happens here; we'll just send back examples
    ids.map { User(id: $0) }
  }
}

//@MainActor
class DataModel: ObservableObject {
  
  @Published var users = [User]()
  var database = DataBase()
  
  func loadUsers() async {
    let ids = Array(1...100)
    
    // Load all users in one hop/"batch"
    let newUsers = await database.loadUsers(ids: ids)
    
    // Back on the main actor to update the UI
    users.append(contentsOf: newUsers)
  }
}

struct ContentView: View {
  @StateObject var model = DataModel()
  
  var body: some View {
    List(model.users) { user in
      Text("User \(user.id)")
    }
    .task {
      await model.loadUsers()
    }
  }
}


PlaygroundPage.current.setLiveView(ContentView())
