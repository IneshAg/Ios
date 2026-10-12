import Foundation

// MARK: - Audition

enum PieceKind: String, Codable, CaseIterable, Hashable {
    case headshot, slate, fullLength, scene

    var symbol: String {
        switch self {
        case .headshot:   "person.crop.square"
        case .slate:      "person.text.rectangle"
        case .fullLength: "figure.stand"
        case .scene:      "film"
        }
    }
}

struct Piece: Identifiable, Hashable, Codable {
    var id = UUID()
    var kind: PieceKind
    var title: String
    var detail: String
    var isDone: Bool
}

struct ScriptLine: Identifiable, Hashable, Codable {
    var id = UUID()
    var character: String
    var text: String
    var isMine: Bool
}

struct ScriptScene: Identifiable, Hashable, Codable {
    var id = UUID()
    var number: Int
    var title: String
    var heading: String
    var lines: [ScriptLine]
    var estimatedSeconds: Int
}

enum AuditionStatus: String, Codable, Hashable {
    case due, ready, sent
}

enum Destination: String, Codable, CaseIterable, Hashable, Identifiable {
    case actorsAccess = "Actors Access"
    case castingNetworks = "Casting Networks"
    case spotlight = "Spotlight"
    case emailOrLink = "Email or link"
    var id: String { rawValue }
    var spec: String {
        switch self {
        case .actorsAccess:    "H.264 .mp4 · 1080p · under 500 MB"
        case .castingNetworks: "H.264 .mp4 · 1080p · up to 300 MB"
        case .spotlight:       "H.264 .mp4 · 1080p"
        case .emailOrLink:     "Private link · 30 days"
        }
    }
}

struct Audition: Identifiable, Hashable, Codable {
    var id = UUID()
    var project: String
    var projectType: String
    var role: String
    var roleSize: String
    var castingOffice: String
    var due: Date
    var asks: [String]
    var pieces: [Piece]
    var scenes: [ScriptScene]
    var destination: Destination
    var status: AuditionStatus
    var sentDate: Date?
    var headshotAsset: String = "Headshot"

    var readyCount: Int { pieces.filter(\.isDone).count }
    var totalCount: Int { pieces.count }
    var nextPiece: Piece? { pieces.first { !$0.isDone } }

    /// The single "Next:" line used on Home and on audition cards.
    var nextAction: String {
        if status == .sent { return "Sent · link active" }
        guard let next = nextPiece else { return "Watch it once, then send" }
        switch next.kind {
        case .headshot:   return "Take your headshot"
        case .slate:      return "Record the slate"
        case .fullLength: return "Record the full-length shot"
        case .scene:      return "Record \(next.title)"
        }
    }

    var hoursLeft: Int { max(0, Int(due.timeIntervalSinceNow / 3600)) }
}

// MARK: - Takes

struct Take: Identifiable, Hashable {
    var id = UUID()
    var number: Int
    var duration: TimeInterval
    var recordedAt: Date
    var isCircled: Bool
    var notes: [String]
    var fileURL: URL?
}

// MARK: - Tape check

struct TapeFinding: Identifiable, Hashable {
    var id = UUID()
    var category: String
    var title: String
    var where_: String
    var advice: String
}

// MARK: - Schedule / practice

struct ScheduleItem: Identifiable, Hashable {
    var id = UUID()
    var when: String
    var time: String
    var title: String
    var detail: String
}

struct PracticePiece: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var detail: String
    var linesLearned: Int
    var linesTotal: Int
}

// MARK: - Profile

struct SlateInfo: Hashable, Codable {
    var name: String = "Kabir Sharma"
    var height: String = "5′ 11″"
    var basedIn: String = "Mumbai"
    var representation: String = ""

    var spoken: String { "\(name). \(height). \(basedIn)." }
}
