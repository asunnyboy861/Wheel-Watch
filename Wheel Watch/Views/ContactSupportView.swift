import SwiftUI

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

struct ContactSupportView: View {
    private let backendURL = "https://feedback-board.iocompile67692.workers.dev/api/feedback"

    private struct SubjectOption: Identifiable {
        let title: String
        let icon: String
        var id: String { title }
    }

    private let subjects: [SubjectOption] = [
        SubjectOption(title: "General", icon: "bubble.left.fill"),
        SubjectOption(title: "Feature Suggestion", icon: "lightbulb.fill"),
        SubjectOption(title: "Bug Report", icon: "ant.fill"),
        SubjectOption(title: "Usage Question", icon: "questionmark.circle.fill"),
        SubjectOption(title: "Performance Issue", icon: "gauge.with.dots.needle.67percent"),
        SubjectOption(title: "UI Improvement", icon: "paintpalette.fill"),
        SubjectOption(title: "Other", icon: "ellipsis.circle.fill")
    ]

    @State private var selectedSubject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    private var effectiveSubject: String {
        selectedSubject == "Other" ? customSubject.trimmingCharacters(in: .whitespaces) : selectedSubject
    }

    private var emailIsValid: Bool {
        email.contains("@") && email.contains(".") && !email.hasPrefix("@") && !email.hasSuffix(".")
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailIsValid
            && !effectiveSubject.isEmpty
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                subjectGrid
                if selectedSubject == "Other" {
                    TextField("Custom subject", text: $customSubject)
                        .textFieldStyle(.roundedBorder)
                }
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Your name")
                TextField("yourname@example.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Your email")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Tell us what's on your mind…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(uiColor: .separator))
                )
                Text("\(message.count) / 1000")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onChange(of: message) { newValue in
                        if newValue.count > 1000 { message = String(newValue.prefix(1000)) }
                    }

                Button {
                    submit()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit || isSubmitting)
                .accessibilityLabel("Submit feedback")

                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let success = successMessage {
                    Label(success, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: .systemGreen))
                }
                if let error = errorMessage {
                    Label(error, systemImage: "xmark.octagon.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: .systemRed))
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subjectGrid: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(subjects.dropLast()) { option in
                    subjectTile(option)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                subjectTile(subjects.last!)
            }
        }
    }

    private func subjectTile(_ option: SubjectOption) -> some View {
        let isSelected = selectedSubject == option.title
        return Button {
            selectedSubject = option.title
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : option.icon)
                    .font(.title3)
                Text(option.title)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color(uiColor: .separator), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : .primary)
        .accessibilityLabel("Subject \(option.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func submit() {
        isSubmitting = true
        successMessage = nil
        errorMessage = nil
        let payload = FeedbackRequest(name: name.trimmingCharacters(in: .whitespaces),
                                      email: email.trimmingCharacters(in: .whitespaces),
                                      subject: effectiveSubject,
                                      message: message.trimmingCharacters(in: .whitespaces),
                                      app_name: "Wheel Watch")
        guard let url = URL(string: backendURL),
              let body = try? JSONEncoder().encode(payload) else {
            errorMessage = "Something went wrong. Please try again."
            isSubmitting = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    successMessage = "Thank you! Your feedback has been sent."
                    message = ""
                } else {
                    errorMessage = error?.localizedDescription ?? "Something went wrong. Please try again."
                }
            }
        }.resume()
    }
}
