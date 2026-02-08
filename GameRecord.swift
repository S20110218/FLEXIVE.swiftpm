import Foundation

struct GameRecord: Identifiable, Codable {
    let id: UUID
    let score: Int
    let clearCount: Int
    let date: Date
}
