import Foundation

enum SampleData {
    static let now = Date()

    static func at(days: Int = 0, hour: Int, minute: Int = 0) -> Date {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: days, to: cal.startOfDay(for: now)) ?? now
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
    }

    static let apartment = ScriptScene(
        number: 1,
        title: "Scene 1",
        heading: "INT. APARTMENT — NIGHT",
        lines: [
            .init(character: "ARJUN", text: "I thought you understood why I had to leave.", isMine: true),
            .init(character: "MAYA",  text: "You never gave me a chance to understand.", isMine: false),
            .init(character: "ARJUN", text: "Because every time I tried, you turned away.", isMine: true),
            .init(character: "MAYA",  text: "So you packed a bag and let me hear it from your sister.", isMine: false),
            .init(character: "ARJUN", text: "(quietly) I didn't know how to say it to your face.", isMine: true),
            .init(character: "MAYA",  text: "You still don't.", isMine: false)
        ],
        estimatedSeconds: 90
    )

    static let goodbye = ScriptScene(
        number: 2,
        title: "Scene 2",
        heading: "EXT. STATION — DAWN",
        lines: [
            .init(character: "MAYA",  text: "Every summer you said next year.", isMine: false),
            .init(character: "ARJUN", text: "And every year I meant it.", isMine: true)
        ],
        estimatedSeconds: 52
    )

    static let lastSummer = Audition(
        project: "The Last Summer",
        projectType: "Feature film",
        role: "Arjun",
        roleSize: "Lead",
        castingOffice: "Northlight Casting",
        due: at(days: 2, hour: 10),
        asks: ["Slate first", "Landscape", "Full length", "Both profiles", "Under 3 min", "Actors Access"],
        pieces: [
            .init(kind: .headshot, title: "Headshot", detail: "Front · taken Sep 20", isDone: true),
            .init(kind: .slate, title: "Slate", detail: "Kabir Sharma · 5′ 11″ · Mumbai · 0:05", isDone: true),
            .init(kind: .scene, title: "Scene 1", detail: "Apartment Confrontation · not shot yet", isDone: false),
            .init(kind: .scene, title: "Scene 2", detail: "Goodbye · any order", isDone: false)
        ],
        scenes: [apartment, goodbye],
        destination: .actorsAccess,
        status: .due
    )

    static let northbound = Audition(
        project: "Northbound",
        projectType: "Series",
        role: "Supporting role",
        roleSize: "Supporting",
        castingOffice: "Ridge Casting",
        due: at(days: 1, hour: 14, minute: 30),
        asks: ["Callback tape", "Slate first"],
        pieces: [
            .init(kind: .headshot, title: "Headshot", detail: "Front", isDone: true),
            .init(kind: .slate, title: "Slate", detail: "0:05", isDone: true),
            .init(kind: .fullLength, title: "Full length", detail: "0:06", isDone: true),
            .init(kind: .scene, title: "Scene 1", detail: "Take 2 chosen", isDone: true),
            .init(kind: .scene, title: "Watch it once", detail: "Then send", isDone: false)
        ],
        scenes: [apartment],
        destination: .actorsAccess,
        status: .ready
    )

    static let guiltyParty = Audition(
        project: "Guilty Party",
        projectType: "Drama",
        role: "Supporting role",
        roleSize: "Supporting",
        castingOffice: "Dev Casting",
        due: at(days: 7, hour: 11),
        asks: ["Slate first"],
        pieces: [
            .init(kind: .headshot, title: "Headshot", detail: "Front", isDone: true),
            .init(kind: .slate, title: "Slate", detail: "", isDone: false),
            .init(kind: .fullLength, title: "Full length", detail: "", isDone: false),
            .init(kind: .scene, title: "Scene 1", detail: "", isDone: false),
            .init(kind: .scene, title: "Scene 2", detail: "", isDone: false)
        ],
        scenes: [apartment],
        destination: .castingNetworks,
        status: .due
    )

    static let winterPlay = Audition(
        project: "Winter Play",
        projectType: "Theatre",
        role: "Ensemble",
        roleSize: "Ensemble",
        castingOffice: "City Rep",
        due: at(days: -13, hour: 18),
        asks: [],
        pieces: [.init(kind: .scene, title: "Monologue", detail: "", isDone: true)],
        scenes: [],
        destination: .emailOrLink,
        status: .sent,
        sentDate: at(days: -13, hour: 18)
    )

    static let auditions = [northbound, lastSummer, guiltyParty, winterPlay]

    static let schedule: [ScheduleItem] = [
        .init(when: "TODAY", time: "6:00 PM", title: "The Last Summer", detail: "Scene practice · 20 min"),
        .init(when: "TOMORROW", time: "2:30 PM", title: "Northbound", detail: "Callback tape due"),
        .init(when: "SUN 11", time: "11:00 AM", title: "Guilty Party", detail: "Record the slate")
    ]

    static let takes: [Take] = [
        .init(number: 1, duration: 88, recordedAt: now.addingTimeInterval(-1200), isCircled: false, notes: ["Rushed the top"]),
        .init(number: 2, duration: 92, recordedAt: now.addingTimeInterval(-720), isCircled: true, notes: ["Found the turn", "Felt true"]),
        .init(number: 3, duration: 90, recordedAt: now, isCircled: false, notes: ["Eyeline drifted"])
    ]

    static let findings: [TapeFinding] = [
        .init(category: "Eyeline", title: "You looked into the lens", where_: "Scene 1 · 0:41 · 4 s", advice: "Casting wants your eyes just beside the lens, on the reader."),
        .init(category: "Reader volume", title: "Maya is louder than you", where_: "Scene 2 · 0:18 · +3 dB", advice: "Lower her track so casting hears you first.")
    ]

    static let practice: [PracticePiece] = [
        .init(title: "Kitchen Argument", detail: "Two-hander · you play Sam", linesLearned: 5, linesTotal: 6),
        .init(title: "Showcase monologue", detail: "Monologue · 1:10", linesLearned: 12, linesTotal: 12)
    ]
}
