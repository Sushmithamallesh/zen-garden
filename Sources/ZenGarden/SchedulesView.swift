import Foundation
import SwiftUI

struct SchedulesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .bottom) {
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
                    .buttonStyle(VermilionButtonStyle(compact: true))
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
                        Text("No schedules")
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
                        .foregroundStyle(GardenTheme.softInk.opacity(0.62))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 18) {
                timeControl(label: "Begins", minute: schedule.startMinute) { newValue in
                    model.settings.updateSchedule(id: schedule.id) { $0.startMinute = newValue }
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(GardenTheme.rakeLine)

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
                            .foregroundStyle(isSelected ? Color.white : GardenTheme.softInk)
                            .frame(width: 29, height: 29)
                            .background(isSelected ? GardenTheme.moss : GardenTheme.ink.opacity(0.055))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text(schedule.isEnabled ? "Active" : "Paused")
                    .font(GardenTypography.label(11, weight: .semibold))
                    .foregroundStyle(schedule.isEnabled ? GardenTheme.moss : GardenTheme.softInk.opacity(0.6))
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
                .foregroundStyle(GardenTheme.softInk.opacity(0.65))
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
}
