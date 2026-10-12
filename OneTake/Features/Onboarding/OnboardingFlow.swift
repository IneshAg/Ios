import SwiftUI
import AuthenticationServices
import UserNotifications

/// 01 Welcome → 02 Sign in → 03 Your slate → 04 Camera & mic → 04b Notifications → Home (first run)
struct OnboardingFlow: View {
    enum Step: Hashable { case signIn, slate, permissions, notifications }
    @Environment(AppStore.self) private var store
    @State private var path: [Step] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView { path.append(.signIn) }
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .signIn:        SignInView { path.append(.slate) }
                    case .slate:         SlateDetailsView { path.append(.permissions) }
                    case .permissions:   PermissionsView { path.append(.notifications) }
                    case .notifications: NotificationsPermissionView { finish() }
                    }
                }
        }
    }

    private func finish() {
        // First run: Home shows "Add your first audition".
        store.auditions = []
        store.isOnboarded = true
    }
}

// MARK: - 01 Welcome

struct WelcomeView: View {
    var onStart: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("OneTake", systemImage: "movieclapper.fill")
                .font(.otHeadline).foregroundStyle(OT.labelPrimary)
                .padding(.top, 16)

            ScriptPreviewCard()
                .padding(.top, 28)

            Spacer()

            Text("Your best take,\nevery time.")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(OT.labelPrimary)
            Text("Learn your lines, tape with a real reader, and send it the way casting asks.")
                .font(.otCallout).foregroundStyle(OT.labelSecondary)
                .padding(.top, 10)

            Spacer().frame(height: 40)
            Button("Get started", action: onStart).buttonStyle(.otPrimary)
            Button("I already have an account", action: onStart)
                .font(.otHeadline).foregroundStyle(OT.labelPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .padding(.horizontal, OT.gutter + 4)
        .otCanvas()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ScriptPreviewCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                Text("INT. YOUR ROOM — TONIGHT").font(.otCaption.weight(.semibold)).foregroundStyle(OT.labelTertiary)
                line("YOU", "I got the audition.", mine: true)
                line("READER", "Great. Send a tape by Friday.", mine: false)
                line("YOU", "Tonight. I'm ready.", mine: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .otCard(radius: 20)
            .rotationEffect(.degrees(-2))

            Label("SC 1 · TK 1", systemImage: "circle.fill")
                .font(.otCaption.weight(.bold)).foregroundStyle(.white)
                .labelStyle(RecLabelStyle())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black, in: Capsule())
                .offset(x: 6, y: -12)
        }
        .padding(.horizontal, 24)
    }

    private func line(_ who: String, _ text: String, mine: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(who).font(.otCaption.weight(.semibold)).foregroundStyle(OT.labelTertiary)
            HStack(spacing: 8) {
                if mine { Capsule().fill(OT.accent).frame(width: 3) }
                Text(text).font(mine ? .otHeadline : .otCallout)
                    .foregroundStyle(mine ? OT.labelPrimary : OT.labelSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct RecLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.system(size: 7)).foregroundStyle(OT.recRed)
            configuration.title
        }
    }
}

// MARK: - 02 Sign in

struct SignInView: View {
    var onContinue: () -> Void
    @State private var email = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sign in or create an account").font(.otLargeTitle).foregroundStyle(OT.labelPrimary)
            Text("Your auditions, reader tracks and takes, on every device you own.")
                .font(.otCallout).foregroundStyle(OT.labelSecondary)

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in onContinue() }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52).clipShape(Capsule())
            .padding(.top, 8)

            HStack { line; Text("or").font(.otFootnote).foregroundStyle(OT.labelTertiary); line }

            Text("Email").font(.otFootnote.weight(.semibold)).foregroundStyle(OT.labelSecondary)
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never)
                .padding(.horizontal, 16).frame(height: 52)
                .background(OT.fillField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button("Continue with email", action: onContinue).buttonStyle(.otSecondary)

            Label("Takes stay on this iPhone until you send them.", systemImage: "lock.fill")
                .font(.otFootnote).foregroundStyle(OT.labelSecondary)
            Spacer()
        }
        .padding(.horizontal, OT.gutter)
        .otCanvas()
    }

    private var line: some View { Rectangle().fill(OT.separator).frame(height: 1) }
}

// MARK: - 03 Your slate

struct SlateDetailsView: View {
    var onContinue: () -> Void
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 16) {
            Text("How casting meets you").font(.otLargeTitle).foregroundStyle(OT.labelPrimary)
            Text("Said at the start of every tape. Tap a line to change it.")
                .font(.otCallout).foregroundStyle(OT.labelSecondary)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionLabel(text: "Slate preview")
                    Spacer()
                    Label("≈ 0:05", systemImage: "waveform").font(.otFootnote).foregroundStyle(OT.labelTertiary)
                }
                slateField($store.slate.name, hint: "from Apple Account")
                slateField($store.slate.height, hint: "height")
                slateField($store.slate.basedIn, hint: "based in")
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Representation").font(.otBody)
                        Text("Leave blank if you represent yourself").font(.otFootnote).foregroundStyle(OT.labelTertiary)
                    }
                    Spacer()
                    Button("Add") {}.font(.otHeadline)
                }
            }
            .padding(20).otCard()

            Spacer()
            Button("Continue", action: onContinue).buttonStyle(.otPrimary)
        }
        .padding(.horizontal, OT.gutter)
        .otCanvas()
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Skip", action: onContinue) } }
    }

    private func slateField(_ text: Binding<String>, hint: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            TextField("", text: text).font(.system(size: 28, weight: .bold))
            Text(hint).font(.otFootnote).foregroundStyle(OT.labelTertiary)
        }
    }
}

// MARK: - 04 Camera & mic

struct PermissionsView: View {
    var onContinue: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your camera and mic, only for your tapes").font(.otLargeTitle).foregroundStyle(OT.labelPrimary)
            VStack(spacing: 4) {
                benefit("viewfinder", "Check before you roll", "Framing, light and sound, in one glance.")
                benefit("waveform", "Start with your voice", "Say “Action” from your mark. No running back to the phone.")
                benefit("lock.fill", "Private until you send", "Takes stay on this phone.")
            }
            Spacer()
            Text("Your iPhone asks next. Tap Allow for each.")
                .font(.otFootnote).foregroundStyle(OT.labelTertiary).frame(maxWidth: .infinity)
            Button("Allow camera & mic") {
                Task { _ = await CameraController.requestAccess(); onContinue() }
            }
            .buttonStyle(.otPrimary)
        }
        .padding(.horizontal, OT.gutter)
        .otCanvas()
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Not now", action: onContinue) } }
        .navigationBarBackButtonHidden()
    }

    private func benefit(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).foregroundStyle(OT.accent)
                .frame(width: 40, height: 40)
                .background(OT.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.otBody)
                Text(detail).font(.otFootnote).foregroundStyle(OT.labelTertiary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 04b Notifications

struct NotificationsPermissionView: View {
    var onContinue: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Never miss a due date").font(.otLargeTitle).foregroundStyle(OT.labelPrimary)
            Text("One reminder, so it never sneaks up on you.").font(.otCallout).foregroundStyle(OT.labelSecondary)

            SectionLabel(text: "Preview").padding(.top, 8)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "movieclapper.fill").foregroundStyle(.white)
                    .frame(width: 38, height: 38).background(OT.accent, in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    HStack { Text("OneTake").font(.otFootnote.weight(.semibold)); Spacer(); Text("8:00 AM").font(.otFootnote).foregroundStyle(OT.labelTertiary) }
                    Text("The Last Summer is due today at 10:00 AM. 2 of 4 ready.").font(.otCallout)
                }
            }
            .padding(14).otCard(radius: 18)

            Spacer()
            Text("Your iPhone asks next. Tap Allow.")
                .font(.otFootnote).foregroundStyle(OT.labelTertiary).frame(maxWidth: .infinity)
            Button("Allow notifications") {
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    onContinue()
                }
            }
            .buttonStyle(.otPrimary)
        }
        .padding(.horizontal, OT.gutter)
        .otCanvas()
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Not now", action: onContinue) } }
        .navigationBarBackButtonHidden()
    }
}
