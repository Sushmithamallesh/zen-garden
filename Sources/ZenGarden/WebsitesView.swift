import SwiftUI

struct BlockedWebsiteList: View {
    @EnvironmentObject private var model: AppModel
    @State private var newWebsite = ""
    @State private var validationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Blocked websites")
                    .font(GardenTypography.display(18, weight: .semibold))

                Spacer()

                let activeCount = model.settings.websites.filter(\.isEnabled).count
                Text("\(activeCount) active")
                    .font(GardenTypography.label(10, weight: .semibold))
                    .foregroundStyle(GardenTheme.moss)
            }

            HStack(spacing: 9) {
                TextField("Add a website, e.g. reddit.com", text: $newWebsite)
                    .textFieldStyle(.plain)
                    .font(GardenTypography.body(14))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(GardenTheme.ink.opacity(0.045))
                    .foregroundStyle(GardenTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .onSubmit(addWebsite)

                Button(action: addWebsite) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 30, height: 30)
                        .background(GardenTheme.vermilion)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Add website")
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(GardenTypography.body(11))
                    .foregroundStyle(GardenTheme.vermilion)
            }

            if model.settings.websites.isEmpty {
                Text("Nothing is blocked yet.")
                    .font(GardenTypography.body(13))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.62))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.settings.websites.enumerated()), id: \.element.id) { index, website in
                        WebsiteRow(website: website)

                        if index < model.settings.websites.count - 1 {
                            Divider()
                                .overlay(GardenTheme.deepPine.opacity(0.07))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(GardenTheme.warmWhite.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(GardenTheme.deepPine.opacity(0.09), lineWidth: 1)
        }
    }

    private func addWebsite() {
        guard !newWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if model.settings.addWebsite(newWebsite) {
            newWebsite = ""
            validationMessage = nil
        } else {
            validationMessage = "Enter a valid website that is not already in the list."
        }
    }
}

private struct WebsiteRow: View {
    @EnvironmentObject private var model: AppModel
    let website: BlockedWebsite

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(website.isEnabled ? GardenTheme.moss : GardenTheme.softInk.opacity(0.24))
                .frame(width: 7, height: 7)

            Text(website.domain)
                .font(GardenTypography.body(14, weight: .medium))
                .foregroundStyle(website.isEnabled ? GardenTheme.ink : GardenTheme.softInk.opacity(0.62))

            Spacer()

            Button {
                model.settings.setWebsiteEnabled(id: website.id, isEnabled: !website.isEnabled)
            } label: {
                Image(systemName: website.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(website.isEnabled ? GardenTheme.moss : GardenTheme.softInk.opacity(0.45))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help(website.isEnabled ? "Disable" : "Enable")

            Button {
                model.settings.deleteWebsite(id: website.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.55))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Remove \(website.domain)")
        }
        .padding(.vertical, 6)
    }
}
