//: [Previous](@previous)

import Foundation
import UIKit

func doAsyncWork() async {
  print("Do async work")
}

func doRegularWork() {
  Task {
    await doAsyncWork()
  }
}

doRegularWork()

//: [Next](@next)
