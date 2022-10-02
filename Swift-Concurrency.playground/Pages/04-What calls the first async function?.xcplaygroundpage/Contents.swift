//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport

//struct ContentView: View {
//    @State private var sourceCode = ""
//
//    var body: some View {
//        ScrollView {
//            Text(sourceCode)
//        }
//        .task {
//            await fetchSource()
//        }
//    }
//
//    func fetchSource() async {
//        do {
//            let url = URL(string: "https://apple.com")!
//
//            let (data, _) = try await URLSession.shared.data(from: url)
//            sourceCode = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
//        } catch {
//            sourceCode = "Failed to fetch apple.com"
//        }
//    }
//}

struct ContentView: View {
    @State private var site = "https://"
    @State private var sourceCode = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Website address", text: $site)
                    .textFieldStyle(.roundedBorder)
                Button("Go") {
                    Task {
                        await fetchSource()
                    }
                }
            }
            .padding()

            ScrollView {
                Text(sourceCode)
            }
            .frame(width: 300, height: 600)
        }
    }

    func fetchSource() async {
        do {
            let url = URL(string: site)!
            let (data, _) = try await URLSession.shared.data(from: url)
            sourceCode = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            sourceCode = "Failed to fetch \(site)"
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())

//: [Next](@next)
