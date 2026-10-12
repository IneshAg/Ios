import SwiftUI

// MARK: - 20 Package · Ready to send

struct PackageView: View {
    enum Phase { case review, sending, failed, sent }

    let auditionID: Audition.ID
    @Environment(AppStore.self) private var store
    @State private var phase: Phase = .review
    @State private var showDestination = false
    @State private var showShare = false
    @State private var progress = 0.0
    @State private var useMobileData = true

    var body: some View {
        if let a = store.audition(auditionID) {
            Group {
                switch phase {
                case .review:  review(a)
                case .sending: SendProgressView(audition: a, progress: progress, onCancel: { phase = .review }, onDrop: { phase = .failed })
                case .failed:  SendFailedView(audition: a, useMobileData: $useMobileData, onRetry: send)
                case .sent:    SentView(audition: a) { store.popToRoot(); store.tab = .auditions }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: phase)
            .otCanvas()
        }
    }

    private func review(_ a: Audition) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ready to send.").font(.otLargeTitle)
                Text("Due \(a.due.otDue) · \(a.readyCount) of \(a.totalCount) ready").font(.otCallout).foregroundStyle(OT.labelSecondary)

                HStack { SectionLabel(text: "On the tape, in order"); Spacer(); Text("2:25").font(.otHeadline) }
                TapeStrip()

                VStack(spacing: 0) {
                    row(symbol: "film", title: "SHARMA_KABIR_ARJUN_THELASTSUMMER.mp4", detail: "Named the way casting asked · one file", value: nil)
                    Button { showDestination = true } label: { row(symbol: "paperplane", title: a.destination.rawValue, detail: nil, value: "184 MB · 1080p") }.buttonStyle(.plain)
                    Button { store.push(.tapeCheck(a.id)) } label: { row(symbol: "checkmark.seal.fill", title: "Tape check", detail: nil, value: "Passed", tint: OT.success) }.buttonStyle(.plain)
                    row(symbol: "waveform", title: "Audio", detail: nil, value: "Both voices clear", tint: OT.success)
                    row(symbol: "play.rectangle", title: "Preview the whole tape", detail: "Exactly what casting gets · 2:25", value: nil)
                }
            }
            .padding(.horizontal, OT.gutter)
            .padding(.bottom, 140)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                Button { send() } label: { Label("Send to \(a.destination.rawValue)", systemImage: "paperplane.fill").labelStyle(TrailingIconLabelStyle()) }
                    .buttonStyle(.otPrimary)
                Button("Choose different takes") { store.push(.takes(a.id)) }
                    .font(.otHeadline).foregroundStyle(OT.labelPrimary).frame(maxWidth: .infinity, minHeight: 48)
            }
            .padding(.horizontal, OT.gutter).background(OT.bgCanvas)
        }
        .sheet(isPresented: $showDestination) { DestinationSheet(auditionID: a.id, showShare: $showShare).presentationDetents([.medium]) }
        .sheet(isPresented: $showShare) { ShareSheet(items: ["OneTake tape — The Last Summer"]) }
    }

    private func row(symbol: String, title: String, detail: String?, value: String?, tint: Color = OT.labelSecondary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.otBody).lineLimit(1)
                if let detail { Text(detail).font(.otFootnote).foregroundStyle(OT.labelTertiary) }
            }
            Spacer()
            if let value { Text(value).font(.otFootnote).foregroundStyle(OT.labelSecondary) }
            Image(systemName: "chevron.forward").font(.caption).foregroundStyle(OT.labelTertiary)
        }
        .frame(minHeight: 54)
        .overlay(alignment: .bottom) { Divider() }
    }

    /// No hold-to-send: one tap sends. "Delivered" only appears once the destination confirms.
    private func send() {
        phase = .sending
        progress = 0
        Task {
            while progress < 1 {
                try? await Task.sleep(for: .milliseconds(60))
                guard phase == .sending else { return }
                progress = min(1, progress + 0.02)
            }
            store.markSent(auditionID)
            Haptics.success()
            phase = .sent
        }
    }
}

struct TapeStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 6).fill(OT.accent.opacity(0.4)).frame(width: 10)
                    RoundedRectangle(cornerRadius: 6).fill(OT.accent.opacity(0.4)).frame(width: 10)
                    RoundedRectangle(cornerRadius: 6).fill(OT.accent).frame(width: geo.size.width * 0.58)
                    RoundedRectangle(cornerRadius: 6).fill(OT.reader)
                }
            }
            .frame(height: 44)
            HStack(spacing: 14) {
                legend("Headshot", "Front", OT.accent.opacity(0.4))
                legend("Slate", "0:05", OT.accent.opacity(0.4))
                legend("Scene 1", "Take 2 · 1:28", OT.accent)
                legend("Scene 2", "Take 1 · 0:52", OT.reader)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tape: headshot, slate, scene 1 take 2, scene 2 take 1. 2 minutes 25.")
    }

    private func legend(_ t: String, _ d: String, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) { RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 8, height: 8); Text(t).font(.otCaption.weight(.semibold)) }
            Text(d).font(.otCaption).foregroundStyle(OT.labelTertiary)
        }
    }
}

// MARK: - 20.1 / 20.2 Where is it going?

struct DestinationSheet: View {
    let auditionID: Audition.ID
    @Binding var showShare: Bool
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Destination.allCases) { d in
                        Button {
                            if let i = store.auditions.firstIndex(where: { $0.id == auditionID }) { store.auditions[i].destination = d }
                            if d == .emailOrLink { dismiss(); showShare = true } else { dismiss() }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) { Text(d.rawValue).font(.otBody); Text(d.spec).font(.otFootnote).foregroundStyle(OT.labelTertiary) }
                                Spacer()
                                if store.audition(auditionID)?.destination == d { Image(systemName: "checkmark.circle.fill").foregroundStyle(OT.accent) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("We match the format, size and file name each site accepts.")
                }
            }
            .navigationTitle("Where’s it going?").navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 20.3 Sending

struct SendProgressView: View {
    let audition: Audition
    let progress: Double
    var onCancel: () -> Void
    var onDrop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Sending to \(audition.destination.rawValue)").padding(.top, 20)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(progress * 100))").font(.system(size: 72, weight: .bold)).monospacedDigit()
                Text("%").font(.otTitle)
            }
            ProgressView(value: progress).tint(OT.accent)
            Text("about \(max(1, Int((1 - progress) * 90))) s left · \(Int(progress * 184)) of 184 MB").font(.otFootnote).foregroundStyle(OT.labelTertiary)
            SectionLabel(text: "Steps").padding(.top, 8)
            step("Joined headshot, slate and 2 scenes", done: true)
            step("Exported 1080p · 184 MB", done: true)
            step("Uploading", done: false, active: true).onTapGesture(perform: onDrop)
            step("Delivered — once \(audition.destination.rawValue) confirms", done: false)
            Text("You can lock your iPhone. It only says Delivered once \(audition.destination.rawValue) confirms it has the file.")
                .font(.otFootnote).foregroundStyle(OT.labelTertiary)
            Spacer()
            Button("Cancel sending", action: onCancel).buttonStyle(.otSecondary)
        }
        .padding(.horizontal, OT.gutter)
    }

    private func step(_ t: String, done: Bool, active: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : active ? "arrow.up.circle.fill" : "circle")
                .foregroundStyle(done ? OT.success : active ? OT.accent : OT.labelTertiary)
            Text(t).font(.otBody).foregroundStyle(done || active ? OT.labelPrimary : OT.labelTertiary)
        }
        .frame(minHeight: 36)
    }
}

// MARK: - 20.4 Not sent yet

struct SendFailedView: View {
    let audition: Audition
    @Binding var useMobileData: Bool
    var onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundStyle(OT.warning).padding(.top, 20)
            Text("Not sent yet").font(.otLargeTitle)
            Text("You lost connection. Your tape is safe on this iPhone and sends on its own when you're back online.")
                .font(.otCallout).foregroundStyle(OT.labelSecondary)
            ScheduleRow(eyebrow: audition.due.formatted(.dateTime.weekday(.abbreviated)).uppercased(), value: "\(audition.hoursLeft)h",
                        title: "Due \(audition.due.otDue)", detail: "Plenty of time — it'll retry automatically")
            Toggle(isOn: $useMobileData) { VStack(alignment: .leading) { Text("Use mobile data"); Text("About 184 MB").font(.otFootnote).foregroundStyle(OT.labelTertiary) } }
            Spacer()
            Button("Try again now", action: onRetry).buttonStyle(.otPrimary)
        }
        .padding(.horizontal, OT.gutter)
    }
}

// MARK: - 21 Sent

struct SentView: View {
    let audition: Audition
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("DELIVERED · CONFIRMED \(Date.now.formatted(.dateTime.weekday(.abbreviated).hour().minute()).uppercased())")
                        .font(.otCaption.weight(.semibold)).foregroundStyle(OT.success)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(OT.success)
                }
                Text("SHARMA_KABIR_ARJUN_THELASTSUMMER.mp4").font(.otFootnote.weight(.semibold))
                Text("2:25 · headshot · slate · 2 scenes").font(.otFootnote).foregroundStyle(OT.labelSecondary)
            }
            .padding(16).otCard(radius: 18).rotationEffect(.degrees(1.5)).padding(.top, 30)

            Text("It’s with casting.").font(.system(size: 38, weight: .bold))
            HStack(alignment: .firstTextBaseline) {
                Text(earlyText).font(.otTitle).foregroundStyle(OT.success)
                Text("Break a leg.").font(.otHeadline).foregroundStyle(OT.labelSecondary)
            }
            Label("Private link copied · works for 30 days", systemImage: "link").font(.otFootnote).foregroundStyle(OT.labelSecondary)
            Label("All your takes stay here if they ask for another", systemImage: "iphone").font(.otFootnote).foregroundStyle(OT.labelSecondary)
            Spacer()
            Button("Done", action: onDone).buttonStyle(.otPrimary)
        }
        .padding(.horizontal, OT.gutter)
        .onAppear { Haptics.success() }
    }

    private var earlyText: String {
        let h = audition.hoursLeft
        return h >= 1 ? "\(h) hours early." : "Right on time."
    }
}
