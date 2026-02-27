import SwiftUI

struct ResultView: View {
    let result: MeetingResult
    @State private var showRaw = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {

            // ── Toggle ──
            Picker("View", selection: $showRaw) {
                Text("Summary").tag(false)
                Text("Transcript").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // ── Content ──
            ScrollView {
                if showRaw {
                    // Raw Transcript
                    Text(result.transcript ?? "No transcript available.")
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                } else {
                    // Structured Summary
                    VStack(alignment: .leading, spacing: 16) {

                        if let minutes = result.minutes, !minutes.isEmpty {
                            SectionCard(title: "Minutes", icon: "list.bullet") {
                                ForEach(minutes, id: \.self) { BulletRow(text: $0) }
                            }
                        }

                        if let points = result.keyDiscussionPoints, !points.isEmpty {
                            SectionCard(title: "Discussion Points", icon: "bubble.left.and.bubble.right") {
                                ForEach(points, id: \.self) { BulletRow(text: $0) }
                            }
                        }

                        if let decisions = result.decisions, !decisions.isEmpty {
                            SectionCard(title: "Decisions", icon: "checkmark.seal") {
                                ForEach(decisions, id: \.decision) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.decision)
                                            .font(.system(size: 14, weight: .medium))
                                        if let speaker = item.speaker {
                                            Label(speaker, systemImage: "person")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }

                        if let actions = result.actionItems, !actions.isEmpty {
                            SectionCard(title: "Action Items", icon: "bolt") {
                                ForEach(actions, id: \.task) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.task)
                                            .font(.system(size: 14, weight: .medium))
                                        HStack(spacing: 12) {
                                            if let owner = item.owner {
                                                Label(owner, systemImage: "person")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                            }
                                            if let deadline = item.deadline {
                                                Label(deadline, systemImage: "calendar")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Meeting Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: showRaw ? (result.transcript ?? "") : summaryText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    var summaryText: String {
        var lines: [String] = ["MEETING SUMMARY\n"]
        result.minutes?.forEach { lines.append("• \($0)") }
        lines.append("\nDECISIONS")
        result.decisions?.forEach { lines.append("• \($0.decision)") }
        lines.append("\nACTION ITEMS")
        result.actionItems?.forEach { lines.append("• \($0.task)") }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Supporting Views

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(1)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct BulletRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(.secondary.opacity(0.4))
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
        }
    }
}
