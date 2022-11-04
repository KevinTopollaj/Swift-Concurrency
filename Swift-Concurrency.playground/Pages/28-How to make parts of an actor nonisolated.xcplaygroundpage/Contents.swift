import UIKit
import CryptoKit
import Foundation
import Darwin

actor Person {
  let username: String
  let password: String
  var isOnline = false
  
  init(username: String, password: String) {
    self.username = username
    self.password = password
  }
  
  nonisolated func passwordHash() -> String {
    let passwordData = Data(password.utf8)
    let hash = SHA256.hash(data: passwordData)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
}

let person = Person(username: "kevin", password: "S3cr3t")
print(person.passwordHash())

// if we wanted to make our User actor conform to Codable, we’d need to implement encode(to:) ourselves as a non-isolated method like this:

actor User: Codable {
  
  enum CodingKeys: CodingKey {
    case username, password
  }
  
  let username: String
  let password: String
  var isOnline = false
  
  init(username: String, password: String) {
    self.username = username
    self.password = password
  }
  
  nonisolated func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(username, forKey: .username)
    try container.encode(password, forKey: .password)
  }
}

let user = User(username: "Kevin", password: "S3cr3t")

if let encoded = try? JSONEncoder().encode(user) {
  let json = String(decoding: encoded, as: UTF8.self)
  print(json)
}
