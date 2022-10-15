//: [Previous](@previous)

import Foundation
import UIKit

import SwiftUI
import PlaygroundSupport

// When you create a regular task from inside an actor it will be isolated to that actor, which means you can use other parts of the actor synchronously:

//actor User {
//
//  func login() {
//    Task {
//      if authenticate(user: "Test", password: "123456") {
//        print("Successfully logged in.")
//      } else {
//        print("Sorry, something went wrong.")
//      }
//    }
//  }
//
//  func authenticate(user: String, password: String) -> Bool {
//    return true
//  }
//}
//
//let user = User()
//
//Task {
//  await user.login()
//}


// A detached task runs concurrently with all other code, including the actor that created it – it effectively has no parent, and therefore has greatly restricted access to the data inside the actor.
// If we were to rewrite the previous actor to use a detached task, it would need to call authenticate() like this:

actor User {

    func login() {
        Task.detached {
            if await self.authenticate(user: "taytay89", password: "n3wy0rk") {
                print("Successfully logged in.")
            } else {
                print("Sorry, something went wrong.")
            }
        }
    }

    func authenticate(user: String, password: String) -> Bool {
        // Complicated logic here
        return true
    }
}

let user = User()

Task {
  await user.login()
}



class ViewModel: ObservableObject { }

struct ContentView: View {
    @StateObject private var model = ViewModel()

    var body: some View {
        Button("Authenticate", action: doWork)
    }

    func doWork() {
      Task.detached {
            for i in 1...10 {
                print("In Task 1: \(i)")
            }
        }

      Task.detached {
            for i in 1...10 {
                print("In Task 2: \(i)")
            }
        }
    }
    
}

PlaygroundPage.current.setLiveView(ContentView())
