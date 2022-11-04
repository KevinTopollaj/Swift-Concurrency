import UIKit

actor DataStore {
  var username = "Anonymous"
  var friends = [String]()
  var highScores = [Int]()
  var favorites = Set<Int>()

  init() {
    //load data
  }
  
  func save() {
    // save data
  }
  
}

func debugLog(dataStore: isolated DataStore) {
    print("Username: \(dataStore.username)")
    print("Friends: \(dataStore.friends)")
    print("High scores: \(dataStore.highScores)")
    print("Favorites: \(dataStore.favorites)")
}

Task {
  let dataStore = DataStore()
  await debugLog(dataStore: dataStore)
}
