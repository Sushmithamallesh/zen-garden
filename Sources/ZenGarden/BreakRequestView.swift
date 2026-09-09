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
        VStack(alignment: .leading, spacing: compact ? 12 : 17) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TEMPORARY ACCESS")
                    .font(GardenTypography.label(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(GardenTheme.vermilion)
                Text("Unblock one website")
                    .font(GardenTypography.display(compact ? 20 : 25, weight: .semibold))
                Text("Choose a duration and enter a reason.")
                    .font(GardenTypography.body(11))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.72))
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
                TextField("Required. Included in today’s email.", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
                    .focused($reasonIsFocused)
                    .textFieldStyle(.plain)
                    .font(GardenTypography.body(13))
                    .padding(11)
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

                Button("Open for \(duration) min", action: submit)
                    .buttonStyle(VermilionButtonStyle(compact: true))
                    .disabled(!canSubmit)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(GardenTypography.body(11))
                    .foregroundStyle(GardenTheme.vermilion)
            }
        }
        .padding(compact ? 2 : 22)
        .frame(width: compact ? nil : 430)
        .onAppear {
            selectSuggestedDomain()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                reasonIsFocused = true
            }
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
            .foregroundStyle(GardenTheme.softInk.opacity(0.68))
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
            validationMessage = "Twitter cannot be temporarily allowed on Sundays."
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
            validationMessage = "This website is already allowed or no longer enabled."
            return
        }
        validationMessage = nil
        onComplete()
    }
}
