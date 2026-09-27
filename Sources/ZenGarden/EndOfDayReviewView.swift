import SwiftUI

/// A deliberately quiet review of the day's temporary access. Opening this
/// window never changes blocking; the user chooses whether to finish the day.
struct EndOfDayReviewView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let records = model.settings.breakRecords(on: now)
            let isComplete = model.settings.isDayComplete(at: now)

            ZStack {
                ZenGardenBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        reviewHeader(now: now, count: records.count, isComplete: isComplete)
                        summaryStrip(records: records, now: now)
                        breakHistory(records: records, now: now)
                        footer(now: now, isComplete: isComplete)
                    }
                    .frame(maxWidth: 560, alignment: .leading)
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .foregroundStyle(GardenTheme.ink)
        }
    }

    private func reviewHeader(now: Date, count: Int, isComplete: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "sun.horizon.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(isComplete ? "DAY COMPLETE" : "DAY REVIEW")
                    .font(GardenTypography.label(10, weight: .bold))
                    .tracking(1.4)
            }
            .foregroundStyle(isComplete ? GardenTheme.moss : GardenTheme.vermilion)

            Text(isComplete ? "Today is complete." : "Today, in view.")
                .font(GardenTypography.display(30, weight: .semibold))
                .tracking(-0.55)

            Text(now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(GardenTypography.body(14, weight: .medium))
                .foregroundStyle(GardenTheme.secondaryText)

            if count == 0 {
                Text("No websites were unblocked today.")
                    .font(GardenTypography.body(13))
                    .foregroundStyle(GardenTheme.secondaryText)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryStrip(records: [BreakRecord], now: Date) -> some View {
        HStack(spacing: 10) {
            ReviewMetric(
                value: "\(records.count)",
                label: records.count == 1 ? "unblock" : "unblocks",
                symbol: "lock.open"
            )
            ReviewMetric(
                value: durationText(for: records, now: now),
                label: "access time",
                symbol: "clock"
            )
        }
    }

    @ViewBuilder
    private func breakHistory(records: [BreakRecord], now: Date) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("TODAY’S ACCESS")
                    .font(GardenTypography.label(10, weight: .bold))
                    .tracking(1.25)
                    .foregroundStyle(GardenTheme.matchaShadow)
                Spacer()
                Text("\(records.count)")
                    .font(GardenTypography.label(11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(GardenTheme.secondaryText)
            }

            if records.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "leaf")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(GardenTheme.moss)
                    Text("Nothing to review")
                        .font(GardenTypography.body(13, weight: .semibold))
                    Text("Your blocklist stayed intact today.")
                        .font(GardenTypography.body(11))
                        .foregroundStyle(GardenTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(records) { record in
                        BreakReviewRow(record: record, now: now)
                    }
                }
            }
        }
        .padding(16)
        .background(GardenTheme.warmWhite.opacity(0.91))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(GardenTheme.elevatedEdge, lineWidth: 1)
        }
        .shadow(color: GardenTheme.elevationShadow.opacity(0.08), radius: 14, y: 6)
    }

    @ViewBuilder
    private func footer(now: Date, isComplete: Bool) -> some View {
        if isComplete {
            HStack {
                Label("Blocking is off until tomorrow.", systemImage: "checkmark.circle.fill")
                    .font(GardenTypography.body(12, weight: .medium))
                    .foregroundStyle(GardenTheme.matchaShadow)
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(SoftButtonStyle())
            }
        } else if !model.settings.isEndOfDayReviewAvailable(at: now) {
            Label("Finishing today becomes available at 7 PM.", systemImage: "clock")
                .font(GardenTypography.body(12, weight: .medium))
                .foregroundStyle(GardenTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(GardenTheme.warmWhite.opacity(0.91))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Finish today’s focus?")
                    .font(GardenTypography.body(13, weight: .semibold))

                HStack(spacing: 10) {
                    Button("Keep blocking") { dismiss() }
                        .buttonStyle(SoftButtonStyle())

                    Button {
                        _ = model.settings.finishDay(at: now)
                    } label: {
                        Label("I’m done for today", systemImage: "checkmark")
                    }
                    .buttonStyle(GardenPrimaryButtonStyle(compact: true))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(GardenTheme.warmWhite.opacity(0.91))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(GardenTheme.elevatedEdge, lineWidth: 1)
            }
        }
    }

    private func durationText(for records: [BreakRecord], now: Date) -> String {
        let total = records.reduce(0) { $0 + $1.activeDuration(until: now) }
        let minutes = Int((total / 60).rounded(.up))
        return minutes == 0 ? "0 min" : "\(minutes) min"
    }
}

private struct ReviewMetric: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GardenTheme.moss)
                .frame(width: 30, height: 30)
                .background(GardenTheme.matchaPale.opacity(0.38))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(GardenTypography.body(16, weight: .semibold))
                    .monospacedDigit()
                Text(label)
                    .font(GardenTypography.body(10, weight: .medium))
                    .foregroundStyle(GardenTheme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GardenTheme.warmWhite.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(GardenTheme.elevatedEdge, lineWidth: 1)
        }
    }
}

private struct BreakReviewRow: View {
    let record: BreakRecord
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GardenTheme.vermilion)
                .frame(width: 30, height: 30)
                .background(GardenTheme.vermilion.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.domain)
                        .font(GardenTypography.body(13, weight: .semibold))
                    Spacer()
                    Text(record.requestedAt.formatted(date: .omitted, time: .shortened))
                        .font(GardenTypography.body(10, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(GardenTheme.secondaryText)
                }

                Text(record.reason)
                    .font(GardenTypography.body(12))
                    .foregroundStyle(GardenTheme.softInk)
                    .lineLimit(3)

                Text(durationText)
                    .font(GardenTypography.body(10, weight: .medium))
                    .foregroundStyle(GardenTheme.secondaryText)
            }
        }
        .padding(12)
        .background(GardenTheme.ink.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.domain), \(durationText), reason: \(record.reason)")
    }

    private var durationText: String {
        let minutes = max(1, Int((record.activeDuration(until: now) / 60).rounded(.up)))
        return "\(minutes) min access"
    }
}
