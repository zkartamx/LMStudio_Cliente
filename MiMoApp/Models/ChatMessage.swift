import Foundation
import SwiftUI
import UIKit

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var text: String?
    var images: [UIImage] = []
    var isUser: Bool

    init(text: String?, images: [UIImage] = [], isUser: Bool) {
        self.id = UUID()
        self.text = text
        self.images = images
        self.isUser = isUser
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.isUser == rhs.isUser &&
        lhs.images.count == rhs.images.count &&
        zip(lhs.images, rhs.images).allSatisfy { $0.pngData() == $1.pngData() }
    }
}

