import SwiftUI

struct RollRadarView: View {
    let position: Position
    let currentValue: Double?
    @StateObject private var viewModel = RollRadarViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if viewModel.isLoading {
                        ProgressView("Scanning the option chain…")
                            .padding(.vertical, 40)
                    } else if let message = viewModel.errorMessage {
                        Label(message, systemImage: "wifi.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .systemOrange))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    } else if viewModel.candidates.isEmpty {
                        Text("No candidates found.")
                            .foregroundStyle(.secondary)
                    } else {
                        sameMonthSection
                        nextMonthSection
                    }
                    Text("Informational only — not investment advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Roll Radar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.load(position: position, currentValue: currentValue) }
        }
    }

    private var sameMonthSection: some View {
        candidateSection(title: "Same month — shift the strike",
                         candidates: viewModel.candidates.filter { $0.isSameMonth })
    }

    private var nextMonthSection: some View {
        candidateSection(title: "Next month — roll out",
                         candidates: viewModel.candidates.filter { !$0.isSameMonth })
    }

    private func candidateSection(title: String, candidates: [RollRadarViewModel.Candidate]) -> some View {
        Group {
            if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                    ForEach(candidates) { candidate in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(position.symbol) \(candidate.strike.formatted()) \(position.type.shortName)")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(candidate.expiry.formatted(.dateTime.month(.abbreviated).day())) · mid ~$\(candidate.mid.formatted(.number.precision(.fractionLength(2))))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("net ~$\(candidate.netCredit.formatted(.number.precision(.fractionLength(2))))")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(candidate.netCredit >= 0 ? Color(uiColor: .systemGreen) : Color(uiColor: .systemRed))
                                Button {
                                    viewModel.copyOrder(for: candidate, position: position)
                                } label: {
                                    Label(viewModel.copied ? "Copied" : "Copy order", systemImage: viewModel.copied ? "checkmark" : "doc.on.doc")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
