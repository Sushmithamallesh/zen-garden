import SwiftUI

struct WebsitesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var newWebsite = ""
    @State private var validationMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                PageHeader(
                    eyebrow: "Boundaries",
                    title: "Distracting paths",
                    subtitle: "These domains will close while focus is active. Subdomains are included automatically."
                )

                addWebsiteCard

                VStack(spacing: 10) {
                    ForEach(model.settings.websites) { website in
                        WebsiteRow(website: website)
                            .environmentObject(model)
                    }
                }

                if model.settings.websites.isEmpty {
                    emptyState
                }
            }
            .padding(34)
        }
    }

    private var addWebsiteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a website")
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            HStack(spacing: 10) {
                TextField("reddit.com", text: $newWebsite)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(GardenTheme.ink.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onSubmit(addWebsite)

                Button("Add", action: addWebsite)
                    .buttonStyle(VermilionButtonStyle(compact: true))
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(GardenTheme.vermilion)
            }
        }
        .zenCard()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 26))
                .foregroundStyle(GardenTheme.moss)
            Text("No paths are closed")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text("Add a domain above whenever a website starts pulling at your attention.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(GardenTheme.softInk.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func addWebsite() {
        guard !newWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if model.settings.addWebsite(newWebsite) {
            newWebsite = ""
            validationMessage = nil
        } else {
            validationMessage = "Enter a valid domain that is not already in the garden."
        }
    }
}

private struct WebsiteRow: View {
    @EnvironmentObject private var model: AppModel
    let website: BlockedWebsite

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(website.isEnabled ? GardenTheme.moss.opacity(0.12) : GardenTheme.ink.opacity(0.05))
                Image(systemName: website.isEnabled ? "leaf.fill" : "leaf")
                    .foregroundStyle(website.isEnabled ? GardenTheme.moss : GardenTheme.softInk.opacity(0.55))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(website.domain)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(website.isEnabled ? "Closed during focus" : "Allowed for now")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.68))
            }

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: { website.isEnabled },
                    set: { model.settings.setWebsiteEnabled(id: website.id, isEnabled: $0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(GardenTheme.moss)

            Button {
                model.settings.deleteWebsite(id: website.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(GardenTheme.softInk.opacity(0.65))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Remove website")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(GardenTheme.warmWhite.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        }
    }
}
