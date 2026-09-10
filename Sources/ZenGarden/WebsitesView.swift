import SwiftUI

struct BlockedWebsiteList: View {
    @EnvironmentObject private var model: AppModel
    @State private var newWebsite = ""
    @State private var validationMessage: String?

    var body: some View {
        let displayedWebsites = model.settings.websitesForBlocking()

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("Blocked websites")
                    .font(GardenTypography.display(20, weight: .semibold))

                Spacer()

                let activeCount = displayedWebsites.filter(\.isEnabled).count
                Text("\(activeCount) active")
                    .font(GardenTypography.label(10, weight: .semibold))
                    .foregroundStyle(GardenTheme.matchaShadow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(GardenTheme.matchaPale.opacity(0.30))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    if newWebsite.isEmpty {
                        Text("Add a website, e.g. reddit.com")
                            .font(GardenTypography.body(13))
                            .foregroundStyle(GardenTheme.secondaryText)
                            .padding(.horizontal, 12)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $newWebsite)
                        .textFieldStyle(.plain)
                        .font(GardenTypography.body(13))
                        .padding(.horizontal, 12)
                        .accessibilityLabel("Add website")
                }
                    .frame(height: 38)
                    .background(GardenTheme.ricePaper.opacity(0.46))
                    .foregroundStyle(GardenTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(GardenTheme.deepPine.opacity(0.14), lineWidth: 1)
                    }
                    .onSubmit(addWebsite)

                Button(action: addWebsite) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 40, height: 40)
                        .background(GardenTheme.moss)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Add website")
                .disabled(newWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(GardenTypography.body(11))
                    .foregroundStyle(GardenTheme.vermilion)
            }

            if displayedWebsites.isEmpty {
                Text("No websites added.")
                    .font(GardenTypography.body(13))
                    .foregroundStyle(GardenTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(displayedWebsites.enumerated()), id: \.element.id) { index, website in
                            WebsiteRow(website: website)

                            if index < displayedWebsites.count - 1 {
                                Divider()
                                    .overlay(GardenTheme.deepPine.opacity(0.07))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: min(CGFloat(displayedWebsites.count) * 43, 270))
                .scrollIndicators(.hidden)
                .background(GardenTheme.ricePaper.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if SundayLockPolicy.isActive(at: Date()) {
                Label("Twitter stays blocked on Sundays", systemImage: "lock.fill")
                    .font(GardenTypography.body(10, weight: .medium))
                    .foregroundStyle(GardenTheme.secondaryText)
            }
        }
        .zenCard()
    }

    private func addWebsite() {
        guard !newWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if model.settings.addWebsite(newWebsite) {
            newWebsite = ""
            validationMessage = nil
        } else {
            validationMessage = "Enter a valid website that isn’t already listed."
        }
    }
}

private struct WebsiteRow: View {
    @EnvironmentObject private var model: AppModel
    @State private var isHovering = false
    let website: BlockedWebsite

    var body: some View {
        let isLocked = model.settings.isDomainLocked(website.domain)

        HStack(spacing: 11) {
            Text(website.domain)
                .font(GardenTypography.body(13, weight: .medium))
                .foregroundStyle(website.isEnabled ? GardenTheme.ink : GardenTheme.secondaryText)

            Spacer()

            Button {
                if !isLocked {
                    model.settings.setWebsiteEnabled(id: website.id, isEnabled: !website.isEnabled)
                }
            } label: {
                Image(systemName: isLocked ? "lock.fill" : (website.isEnabled ? "checkmark.circle.fill" : "circle"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle((website.isEnabled || isLocked) ? GardenTheme.moss : GardenTheme.secondaryText)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .help(isLocked ? "Locked on Sundays" : (website.isEnabled ? "Disable" : "Enable"))

            Button {
                model.settings.deleteWebsite(id: website.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(GardenTheme.secondaryText.opacity(isHovering ? 1 : 0.72))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .help("Remove \(website.domain)")
            .disabled(isLocked)
        }
        .padding(.vertical, 3)
        .padding(.leading, 2)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(GardenTheme.ink.opacity(isHovering ? 0.035 : 0))
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}
