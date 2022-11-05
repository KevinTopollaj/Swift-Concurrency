import UIKit
import Foundation

extension URLSession {
  func decode<T: Decodable>(_ type: T.Type = T.self,
                            from url: URL,
                            keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                            dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
                            dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate) async throws -> T {
    
    let (data, _) = try await data(from: url)
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = keyDecodingStrategy
    decoder.dataDecodingStrategy = dataDecodingStrategy
    decoder.dateDecodingStrategy = dateDecodingStrategy
    
    let decoded = try decoder.decode(T.self, from: data)
    return decoded
  }
}

struct User: Codable {
    let id: UUID
    let name: String
    let age: Int
}

struct Message: Codable {
    let id: Int
    let user: String
    let text: String
}

Task {
  
  do {
    
    // Fetch and decode a specific type
    let url1 = URL(string: "https://hws.dev/user-24601.json")!
    let user = try await URLSession.shared.decode(User.self ,from: url1)
    print("Downloaded \(user.name)")
    
    // Infer the type because Swift has type annotation
    let url2 = URL(string: "https://hws.dev/inbox.json")!
    let messages: [Message] = try await URLSession.shared.decode(from: url2)
    print("Downloaded \(messages.count) messages")
    
    // Create a custom URLSession and decode a Double array from that
    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    let session = URLSession(configuration: config)
    
    let url3 = URL(string: "https://hws.dev/readings.json")!
    let readings = try await session.decode([Double].self, from: url3)
    print("Downloaded \(readings.count) readings")
    
  } catch {
    print("Download error: \(error.localizedDescription)")
  }
  
}

