//: [Previous](@previous)

import Foundation
import UIKit
import SwiftUI
import PlaygroundSupport
import CoreLocation
import CoreLocationUI

@MainActor class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  
  // stores a continuation to track whether we have the location coordinate or an error
  var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Error>?
  // track an instance of CLLocationManager that does the work of finding the user
  var manager = CLLocationManager()
  
  override init() {
    super.init()
    
    manager.delegate = self
  }
  
  // async function that requests the user’s location and creates a continuation we can stash away and use later.
  func requestLocation() async throws -> CLLocationCoordinate2D? {
    try await withCheckedThrowingContinuation { continuation in
      locationContinuation = continuation
      manager.requestLocation()
    }
  }
  
  // delegate methods, Both of these need to resume our continuation.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationContinuation?.resume(returning: locations.first?.coordinate)
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationContinuation?.resume(throwing: error)
  }
  
}

struct ContentView: View {
  
  @StateObject private var locationManager = LocationManager()
  
  var body: some View {
    LocationButton {
      Task {
        if let location = try? await locationManager.requestLocation() {
          print("Location: \(location)")
        } else {
          print("Location unknown.")
        }
      }
    }
    .frame(height: 44)
    .foregroundColor(.white)
    .clipShape(Capsule())
    .padding()
  }
}




PlaygroundPage.current.setLiveView(ContentView())

//: [Next](@next)
