import Foundation
import SwiftUI

struct SchedulesView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .center) {
                    PageHeader(
                        eyebrow: "",
                        title: "Schedules",
                        subtitle: "Start and end focus automatically."
                    )
                    Spacer()
                    Button {
                        model.settings.addSchedule()
                    } label: {
                        Label("Add schedule", systemImage: "plus")
                    }
                    .buttonStyle(SoftButtonStyle())

                    Button("Done") { dismiss() }
                        .buttonStyle(GardenPrimaryButtonStyle(compact: true))
                        .keyboardShortcut(.cancelAction)
                }

                VStack(spacing: 14) {
                    ForEach(model.settings.schedules) { schedule in
                        ScheduleCard(schedule: schedule)
                            .environmentObject(model)
                    }
                }

                if model.settings.schedules.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 27))
                            .foregroundStyle(GardenTheme.moss)
                        Text("No custom schedules")
                            .font(GardenTypography.display(17, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(45)
                }
            }
            .padding(34)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ScheduleCard: View {
    @EnvironmentObject private var model: AppModel
    let schedule: FocusSchedule

    private let days: [(String, Int)] = [
        ("S", 1), ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 13) {
                TextField(
                    "Schedule name",
                    text: Binding(
                        get: { schedule.name },
                        set: { newName in
                            model.settings.updateSchedule(id: schedule.id) { $0.name = newName }
                        }
                    )
                )
                .textFieldStyle(.plain)
                .font(GardenTypography.display(18, weight: .medium))

                Spacer()

                Toggle(
                    "",
                    isOn: Binding(
                        get: { schedule.isEnabled },
                        set: { enabled in
                            model.settings.updateSchedule(id: schedule.id) { $0.isEnabled = enabled }
                        }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(GardenTheme.moss)

                Button {
                    model.settings.deleteSchedule(id: schedule.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(GardenTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 18) {
                timeControl(label: "Begins", minute: schedule.startMinute) { newValue in
                    model.settings.updateSchedule(id: schedule.id) { $0.startMinute = newValue }
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(GardenTheme.secondaryText)

                timeControl(label: "Ends", minute: schedule.endMinute) { newValue in
                    model.settings.updateSchedule(id: schedule.id) { $0.endMinute = newValue }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    let isSelected = schedule.weekdays.contains(day.1)
                    Button {
                        model.settings.updateSchedule(id: schedule.id) { current in
                            if current.weekdays.contains(day.1) {
                                current.weekdays.remove(day.1)
                            } else {
                                current.weekdays.insert(day.1)
                            }
                        }
                    } label: {
                        Text(day.0)
                            .font(GardenTypography.label(11, weight: .bold))
                            .foregroundStyle(isSelected ? Color.white : GardenTheme.secondaryText)
                            .frame(width: 29, height: 29)
                            .background(isSelected ? GardenTheme.moss : GardenTheme.ink.opacity(0.055))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(dayName(for: day.1))
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }

                Spacer()

                Text(schedule.isEnabled ? "Active" : "Paused")
                    .font(GardenTypography.label(11, weight: .semibold))
                    .foregroundStyle(schedule.isEnabled ? GardenTheme.moss : GardenTheme.secondaryText)
            }
        }
        .zenCard()
        .opacity(schedule.isEnabled ? 1 : 0.82)
    }

    private func timeControl(
        label: String,
        minute: Int,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(GardenTypography.label(9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(GardenTheme.secondaryText)
            DatePicker(
                "",
                selection: Binding(
                    get: { date(for: minute) },
                    set: { onChange(minutes(from: $0)) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.field)
        }
    }

    private func date(for minute: Int) -> Date {
        let start = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .minute, value: minute, to: start) ?? start
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func dayName(for weekday: Int) -> String {
        switch weekday {
        case 1: "Sunday"
        case 2: "Monday"
        case 3: "Tuesday"
        case 4: "Wednesday"
        case 5: "Thursday"
        case 6: "Friday"
        case 7: "Saturday"
        default: "Day"
        }
    }
}
