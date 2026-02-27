import SwiftUI
import Combine
// MARK: - History Store
class HistoryStore: ObservableObject {
    @Published var items: [HistoryItem] = []

    init() { load() }

    func save(_ result: MeetingResult, title: String) {
        let item = HistoryItem(id: UUID(), title: title, date: Date(), result: result)
        items.insert(item, at: 0)
        if items.count > 20 { items = Array(items.prefix(20)) }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "meeting_history")
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "meeting_history"),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            items = decoded
        }
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }
}

struct HistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let date: Date
    let result: MeetingResult
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var history = HistoryStore()

    @State private var showingResult = false
    @State private var result: MeetingResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var showAudioPicker = false
    @State private var statusMessage = ""
    @State private var showHistory = false
    @State private var selectedHistoryItem: HistoryItem?
    @State private var showCarbon = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning."
        case 12..<17: return "Good afternoon."
        default: return "Good evening."
        }
    }


    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ──
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(greeting)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .kerning(1.5)

                            Text("Capture your\nmeeting.")
                                .font(.system(size: 38, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineSpacing(2)
                        }

                        Spacer()
                        
                        Button {
                            showCarbon = true
                        } label: {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.green)
                                )
                        }
                        .popover(isPresented: $showCarbon, arrowEdge: .top) {
                            CarbonPopover(meetingCount: history.items.count)
                        }
                        Spacer()

                        // History Button
                        Button {
                            showHistory = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(width: 40, height: 40)

                                if !history.items.isEmpty {
                                    Text("\(min(history.items.count, 9))")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .popover(isPresented: $showHistory, arrowEdge: .top) {
                            HistoryPopover(history: history, onSelect: { item in
                                selectedHistoryItem = item
                                showHistory = false
                            })
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 28)
                    
                    Spacer()
                    
                   

                    // ── Status ──
                    if !statusMessage.isEmpty {
                        HStack(spacing: 8) {
                            if isLoading { ProgressView().scaleEffect(0.8) }
                            Text(statusMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                    }

                    // ── Buttons ──
                    VStack(spacing: 12) {
                        ActionButton(
                            icon: recorder.isRecording ? "stop.circle.fill" : "mic.fill",
                            label: recorder.isRecording ? "Stop Recording" : "Record Meeting",
                            color: recorder.isRecording ? .red : .primary,
                            isActive: recorder.isRecording
                        ) { handleRecord() }

                        ActionButton(icon: "waveform", label: "Upload Audio", color: .primary, isActive: false) {
                            showAudioPicker = true
                        }

                        ActionButton(icon: "photo", label: "Upload Image", color: .primary, isActive: false) {
                            showImagePicker = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(isPresented: $showingResult) {
                if let result = result { ResultView(result: result) }
            }
            .navigationDestination(item: $selectedHistoryItem) { item in
                ResultView(result: item.result)
            }
            .sheet(isPresented: $showAudioPicker) {
                AudioPickerView { url in handleAudioFile(url: url) }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView { urls in handleImages(urls: urls) }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Handlers

    func handleRecord() {
        if recorder.isRecording {
            recorder.stopRecording { audioURL in
                guard let audioURL else { return }
                uploadAndProcess(fileURL: audioURL)
            }
        } else {
            recorder.startRecording()
            statusMessage = "Recording..."
        }
    }

    func handleAudioFile(url: URL) {
        uploadAndProcess(fileURL: url)
    }

    func handleImages(urls: [URL]) {
        guard !urls.isEmpty else { return }
        isLoading = true
        statusMessage = "Processing images..."

        Task {
            do {
                let meetingResult = try await APIService.processImages(fileURLs: urls)
                await MainActor.run {
                    result = meetingResult
                    history.save(meetingResult, title: "Image Notes — \(formattedDate())")
                    isLoading = false
                    statusMessage = ""
                    showingResult = true
                    NotificationService.send(
                           title: "Meeting Ready ✓",
                           body: "Your meeting summary is ready to view."
                       )
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    statusMessage = ""
                }
            }
        }
    }
    func uploadAndProcess(fileURL: URL) {
        isLoading = true
        statusMessage = "Transcribing..."

        Task {
            do {
                let meetingResult = try await APIService.processMeeting(fileURL: fileURL)
                await MainActor.run {
                    result = meetingResult
                    history.save(meetingResult, title: "Meeting — \(formattedDate())")
                    isLoading = false
                    statusMessage = ""
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    statusMessage = ""
                }
            }
        }
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: Date())
    }
}

// MARK: - History Popover
struct HistoryPopover: View {
    @ObservedObject var history: HistoryStore
    let onSelect: (HistoryItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if history.items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                        Text("No summaries yet")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(history.items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.primary)
                                    Text(item.date, style: .relative)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete { history.delete(at: $0) }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Recent")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(width: 280, height: 360)
    }
}


struct CarbonPopover: View {
    let meetingCount: Int

    // Assumptions:
    // Each meeting replaces ~10 printed pages
    // 1 tree = 8,333 pages
    // 1 page = 4g CO2
    var pagesAvoided: Int { meetingCount * 10 }
    var treesSaved: Double { Double(pagesAvoided) / 8333.0 }
    var carbonReduced: Double { Double(pagesAvoided) * 4.0 } // in grams

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("Your Impact")
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Stats
            VStack(spacing: 0) {
                CarbonRow(
                    icon: "doc.fill",
                    iconColor: .blue,
                    label: "Pages Avoided",
                    value: "\(pagesAvoided)",
                    unit: "pages"
                )
                Divider().padding(.leading, 52)

                CarbonRow(
                    icon: "tree.fill",
                    iconColor: .green,
                    label: "Trees Saved",
                    value: String(format: "%.4f", treesSaved),
                    unit: "trees"
                )
                Divider().padding(.leading, 52)

                CarbonRow(
                    icon: "cloud.fill",
                    iconColor: .gray,
                    label: "CO₂ Reduced",
                    value: carbonReduced < 1000
                        ? String(format: "%.1f", carbonReduced)
                        : String(format: "%.2f", carbonReduced / 1000),
                    unit: carbonReduced < 1000 ? "grams" : "kg"
                )
            }

            // Footer
            Text("Based on \(meetingCount) meeting\(meetingCount == 1 ? "" : "s") processed · 10 pages/meeting avg")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(width: 280)
    }
}

struct CarbonRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.primary)

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
