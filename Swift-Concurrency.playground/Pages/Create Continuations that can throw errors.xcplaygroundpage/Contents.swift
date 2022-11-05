import UIKit

struct Contact: Decodable, Identifiable {
  let id: Int
  let name: String
  let lastname: String
}

func fetchContacts(completion: @escaping ([Contact]) -> Void) {
  let url = URL(string: "https://yourContactListAPI")!
  
  URLSession.shared.dataTask(with: url) { data, response, error in
    if let data = data {
      if let contacts = try? JSONDecoder().decode([Contact].self, from: data) {
        completion(contacts)
        return
      }
    }
    completion([])
  }.resume()
}

enum FetchError: Error {
  case noContacts
}

func fetchContacts() async -> [Contact] {
  do {
    return try await withCheckedThrowingContinuation { continuation in
      fetchContacts { contacts in
        if contacts.isEmpty {
          continuation.resume(throwing: FetchError.noContacts)
        } else {
          continuation.resume(returning: contacts)
        }
      }
    }
  } catch {
    return [
      Contact(id: 1, name: "Tom", lastname: "Doe")
    ]
  }
}

Task {
  let contacts = await fetchContacts()
  print("Downloaded \(contacts.count) contacts.")
}

