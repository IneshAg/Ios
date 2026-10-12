import SwiftUI

/// H0 Home — iteration D1: the whole photo card is the button; one "Next:" line, readiness dial top-right.
struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let next = store.nextPriority {
                    NextPriorityCard(audition: next) { open(next) }
                        .padding(.top, 18)
                    pickUp.padding(.top, 26)
                    schedule.padding(.top, 22)
                } else {
                    FirstRunCard { store.showAddAudition = true }.padding(.top, 18)
                }
            }
            .padding(.horizontal, OT.gutter)
            .padding(.bottom, 120)
        }
        .otCanvas()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                Text(store.auditions.isEmpty ? "Welcome, \(firstName)" : "\(greeting), \(firstName)")
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(OT.labelPrimary)
            }
            Spacer()
            Button { store.showAddAudition = true } label: {
                Image(systemName: "plus").font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(OT.labelOnAccent)
                    .frame(width: 44, height: 44).background(OT.accent, in: Circle())
            }
            .accessibilityLabel("Add an audition")
        }
        .padding(.top, 8)
    }

    private var firstName: String { store.slate.name.components(separatedBy: " ").first ?? "" }
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening"
    }

    // MARK: Sections

    private var pickUp: some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionLabel(text: "Pick up where you left off")
            Button {
                if let a = store.auditions.first(where: { $0.project == "The Last Summer" }) {
                    store.push(.prepare(a.id, sceneIndex: 0))
                }
            } label: {
                ScheduleRow(eyebrow: "LINES", value: "3 of 5", title: "The Last Summer · Scene 1",
                            detail: "Practice · stopped at line 14 of 18",
                            trailing: AnyView(Text("Resume").font(.otFootnote.weight(.semibold)).foregroundStyle(OT.accent)
                                .padding(.horizontal, 12).padding(.vertical, 5).background(OT.accentSoft, in: Capsule())))
            }
            .buttonStyle(.plain)
        }
    }

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionLabel(text: "Your schedule")
            ForEach(SampleData.schedule) { item in
                Button {
                    if let a = store.auditions.first(where: { $0.project == item.title }) { store.push(.auditionDetail(a.id)) }
                } label: {
                    ScheduleRow(eyebrow: item.when, value: item.time, title: item.title, detail: item.detail)
                }
                .buttonStyle(.plain)
                if item.id != SampleData.schedule.last?.id { Divider() }
            }
        }
    }

    // MARK: Routing — the card opens whatever the next piece needs

    private func open(_ audition: Audition) {
        Haptics.impact()
        guard let next = audition.nextPiece else { store.push(.package(audition.id)); return }
        switch next.kind {
        case .headshot: store.push(.headshots)
        case .slate, .fullLength: store.push(.shootSetup(audition.id))
        case .scene:
            if next.title == "Watch it once" { store.push(.package(audition.id)) }
            else { store.push(.prepare(audition.id, sceneIndex: 0)) }
        }
    }
}

// MARK: - Next priority card

struct NextPriorityCard: View {
    let audition: Audition
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                HeadshotImage(name: audition.headshotAsset)
                    .frame(height: 360).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.15), .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Label(dueText, systemImage: "clock")
                            .font(.otFootnote.weight(.semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.black.opacity(0.45), in: Capsule())
                        Spacer()
                        ReadinessDial(done: audition.readyCount, total: audition.totalCount, onDark: true)
                            .padding(6).background(.black.opacity(0.35), in: Circle())
                    }
                    Spacer()
                    Text("NEXT PRIORITY").font(.otEyebrow).foregroundStyle(.white.opacity(0.8))
                    Text(audition.project).font(.otHero).foregroundStyle(.white).padding(.top, 2)
                    Text("\(audition.projectType) · \(audition.role)").font(.otCallout).foregroundStyle(.white.opacity(0.85))
                    Rectangle().fill(.white.opacity(0.25)).frame(height: 1).padding(.vertical, 12)
                    HStack {
                        Text("Next: \(audition.nextAction)").font(.otHeadline).foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.forward").font(.headline).foregroundStyle(.white)
                    }
                }
                .padding(20)
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: OT.cardRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: OT.cardRadius, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("\(audition.project), \(audition.readyCount) of \(audition.totalCount) ready. Next: \(audition.nextAction)")
    }

    private var dueText: String {
        let h = audition.hoursLeft
        if h < 24 { return "Due in \(h) h · \(audition.due.formatted(date: .omitted, time: .shortened))" }
        if h < 48 { return "Due tomorrow, \(audition.due.formatted(date: .omitted, time: .shortened))" }
        return "Due \(audition.due.otDue)"
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - First run

struct FirstRunCard: View {
    var onAdd: () -> Void
    var body: some View {
        Button(action: onAdd) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "plus").font(.title2.weight(.semibold)).foregroundStyle(OT.labelOnAccent)
                    .frame(width: 44, height: 44).background(OT.accent, in: Circle())
                Text("Add your first audition").font(.system(size: 24, weight: .bold)).foregroundStyle(OT.labelPrimary)
                Text("Paste a casting notice, scan the sides or forward the email. OneTake works out what they want.")
                    .font(.otCallout).foregroundStyle(OT.labelSecondary).multilineTextAlignment(.leading)
                Divider().padding(.vertical, 4)
                HStack {
                    Text("Next: Paste a casting notice").font(.otHeadline).foregroundStyle(OT.labelPrimary)
                    Spacer()
                    Image(systemName: "chevron.forward").foregroundStyle(OT.labelTertiary)
                }
            }
            .padding(20)
            .otCard()
        }
        .buttonStyle(PressableCardStyle())
    }
}
