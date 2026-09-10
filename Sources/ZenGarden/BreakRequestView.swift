import SwiftUI

struct BreakRequestView: View {
    @EnvironmentObject private var model: AppModel
    @SwiftUI.FocusState private var reasonIsFocused: Bool
    @State private var selectedDomain = ""
    @State private var reason = ""
    @State private var duration = 10
    @State private var validationMessage: String?

    let compact: Bool
    let onComplete: () -> Void

    private let durations = [5, 10, 15]

    init(compact: Bool, onComplete: @escaping () -> Void) {
        self.compact = compact
        self.onComplete = onComplete
    }

    var body: some View {
        Group {
            if compact {
                compactContent
            } else {
                standardContent
            }
        }
        .onAppear {
            selectSuggestedDomain()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                reasonIsFocused = true
            }
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                Button(action: onComplete) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .frame(width: 30, height: 30)
                        .background(GardenTheme.ink.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Back")

                VStack(alignment: .leading, spacing: 1) {
                    Text("Unblock a website")
                        .font(GardenTypography.body(13, weight: .semibold))
                    Text("A reason is required")
                        .font(GardenTypography.body(10, weight: .medium))
                        .foregroundStyle(GardenTheme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Website")
                Picker("Website", selection: $selectedDomain) {
                    ForEach(enabledDomains, id: \.self) { domain in
                        Text(domain).tag(domain)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Reason")
                ZStack(alignment: .topLeading) {
                    if reason.isEmpty {
                        Text("What do you need access for?")
                            .font(GardenTypography.body(12))
                            .foregroundStyle(GardenTheme.secondaryText)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $reason, axis: .vertical)
                        .lineLimit(2...3)
                        .focused($reasonIsFocused)
                        .textFieldStyle(.plain)
                        .font(GardenTypography.body(12))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .accessibilityLabel("Reason")
                }
                    .background(GardenTheme.ink.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(GardenTheme.ink.opacity(reasonIsFocused ? 0.13 : 0.06), lineWidth: 1)
                    }
                    .onSubmit(submit)
            }

            HStack(spacing: 7) {
                ForEach(durations, id: \.self) { minutes in
                    Button {
                        duration = minutes
                    } label: {
                        Text("\(minutes) min")
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(CompactDurationButtonStyle(isSelected: duration == minutes))
                }
            }

            Button(action: submit) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open")
                    Text("Unblock for \(duration) min")
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.58)
                }
            }
            .buttonStyle(CompactAccessButtonStyle())
            .disabled(!canSubmit)

            validationText
        }
    }

    private var standardContent: some View {
        VStack(alignment: .leading, spacing: 17) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TEMPORARY ACCESS")
                    .font(GardenTypography.label(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(GardenTheme.vermilion)
                Text("Unblock a website")
                    .font(GardenTypography.display(25, weight: .semibold))
                Text("Choose how long and add a reason.")
                    .font(GardenTypography.body(11))
                    .foregroundStyle(GardenTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("Website")
                Picker("Website", selection: $selectedDomain) {
                    ForEach(enabledDomains, id: \.self) { domain in
                        Text(domain).tag(domain)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("Reason")
                ZStack(alignment: .topLeading) {
                    if reason.isEmpty {
                        Text("What do you need access for?")
                            .font(GardenTypography.body(13))
                            .foregroundStyle(GardenTheme.secondaryText)
                            .padding(11)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $reason, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($reasonIsFocused)
                        .textFieldStyle(.plain)
                        .font(GardenTypography.body(13))
                        .padding(11)
                        .accessibilityLabel("Reason")
                }
                    .background(GardenTheme.ink.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .onSubmit(submit)
            }

            HStack(spacing: 8) {
                ForEach(durations, id: \.self) { minutes in
                    Button {
                        duration = minutes
                    } label: {
                        Text("\(minutes) min")
                            .font(GardenTypography.label(11, weight: .semibold))
                            .foregroundStyle(duration == minutes ? Color.white : GardenTheme.softInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(duration == minutes ? GardenTheme.moss : GardenTheme.ink.opacity(0.055))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Unblock for \(duration) min", action: submit)
                    .buttonStyle(GardenPrimaryButtonStyle(compact: true))
                    .disabled(!canSubmit)
            }

            validationText
        }
        .padding(22)
        .frame(width: 430)
    }

    @ViewBuilder
    private var validationText: some View {
        if let validationMessage {
            Text(validationMessage)
                .font(GardenTypography.body(10, weight: .medium))
                .foregroundStyle(GardenTheme.vermilion)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var enabledDomains: [String] {
        model.settings.availableBreakDomains()
    }

    private var canSubmit: Bool {
        model.settings.focusState().isActive
            && !selectedDomain.isEmpty
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(GardenTypography.label(9, weight: .bold))
            .tracking(1.1)
            .foregroundStyle(GardenTheme.secondaryText)
    }

    private func selectSuggestedDomain() {
        guard selectedDomain.isEmpty else { return }
        if let last = model.browserBlocker.lastBlockedDomain,
           enabledDomains.contains(last) {
            selectedDomain = last
        } else {
            selectedDomain = enabledDomains.first ?? ""
        }
    }

    private func submit() {
        guard model.settings.focusState().isActive else {
            validationMessage = "Focus is no longer active."
            return
        }
        if model.settings.isDomainLocked(selectedDomain) {
            validationMessage = "Twitter stays blocked all day Sunday."
            return
        }
        guard canSubmit else {
            validationMessage = "Choose a website and enter a reason."
            return
        }
        guard model.settings.requestBreak(
                  domain: selectedDomain,
                  reason: reason,
                  minutes: duration
              )
        else {
            validationMessage = "That website is no longer blocked."
            return
        }
        validationMessage = nil
        onComplete()
    }
}

private struct CompactDurationButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.body(10, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : GardenTheme.matchaShadow)
            .background(
                isSelected
                    ? GardenTheme.moss
                    : GardenTheme.matchaPale.opacity(configuration.isPressed ? 0.34 : 0.24)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(GardenTheme.matchaShadow.opacity(0.09), lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct CompactAccessButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.body(11, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(configuration.isPressed ? GardenTheme.mossPressed : GardenTheme.moss)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isEnabled ? 1 : 0.42)
            .scaleEffect(configuration.isPressed && isEnabled && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
