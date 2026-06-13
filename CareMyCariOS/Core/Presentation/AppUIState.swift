import Foundation

enum AppUIState: Equatable {
    case idle
    case loading(String)
    case empty(title: String, systemImage: String, message: String)
    case error(title: String, systemImage: String, message: String)
}

