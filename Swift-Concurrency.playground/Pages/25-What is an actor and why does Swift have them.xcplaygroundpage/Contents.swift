import UIKit

actor User {
  
  var score = 10
  
  func printScore() {
    print("My score is \(score)")
  }
  
  func copyScore(from other: User) async {
    score = await other.score
  }
}

let actor1 = User()
let actor2 = User()


Task {
  await print(actor1.score)
  await actor1.copyScore(from: actor2)
}
