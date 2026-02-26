import SwiftUI
import Domain

// MARK: - Draft Model

/// Editable snapshot of all text fields for one localization.
private struct LocalizationDraft: Equatable {
    var whatsNew: String
    var description: String
    var keywords: String
    var marketingUrl: String
    var supportUrl: String
    var promotionalText: String

    init(from loc: LocalizationSummary) {
        whatsNew       = loc.whatsNew       ?? ""
        description    = loc.description    ?? ""
        keywords       = loc.keywords       ?? ""
        marketingUrl   = loc.marketingUrl   ?? ""
        supportUrl     = loc.supportUrl     ?? ""
        promotionalText = loc.promotionalText ?? ""
    }

    /// Produces only fields whose values differ from the original.
    func changedFields(from original: LocalizationSummary) -> (
        whatsNew: String?, description: String?, keywords: String?,
        marketingUrl: String?, supportUrl: String?, promotionalText: String?
    ) {
        func changed(_ draft: String, _ original: String?) -> String? {
            draft != (original ?? "") ? draft : nil
        }
        return (
            changed(whatsNew,        original.whatsNew),
            changed(description,     original.description),
            changed(keywords,        original.keywords),
            changed(marketingUrl,    original.marketingUrl),
            changed(supportUrl,      original.supportUrl),
            changed(promotionalText, original.promotionalText)
        )
    }

    var isEmpty: Bool {
        whatsNew.isEmpty && description.isEmpty && keywords.isEmpty
            && marketingUrl.isEmpty && supportUrl.isEmpty && promotionalText.isEmpty
    }
}

// MARK: - View

/// Screen 7 — list all version localizations with inline multi-field editing.
struct VersionLocalizationsView: View {
    let version: ASCVersion
    let detailRepository: any VersionDetailRepository
    let onBack: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var localizations: [LocalizationSummary] = []
    @State private var isLoading = true
    @State private var loadError: String? = nil

    // Editing state
    @State private var editingId: String? = nil
    @State private var draft: LocalizationDraft? = nil
    @State private var savingId: String? = nil
    @State private var saveError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            actionBar
        }
        .task { await loadLocalizations() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.accentPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Localizations")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if localizations.isEmpty {
                    emptyView
                } else {
                    localizationsList
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
                Text("Loading localizations…")
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 32)
    }

    private func errorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(BaseColors.systemOrange)
                Text("Failed to load")
                    .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
            }
            Text(error)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(3)
            Button("Retry") { Task { await loadLocalizations() } }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accentPrimary)
                .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BaseColors.systemOrange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BaseColors.systemOrange.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.vertical, 8)
    }

    private var emptyView: some View {
        Text("No localizations found")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 32)
    }

    private var localizationsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(localizations.enumerated()), id: \.element.id) { idx, loc in
                if idx > 0 {
                    Rectangle().fill(theme.dividerColor).frame(height: 1)
                }
                localeRow(loc)
            }
        }
        .background(card)
    }

    // MARK: - Locale Row

    private func localeRow(_ loc: LocalizationSummary) -> some View {
        let isEditing = editingId == loc.id
        let isSaving = savingId == loc.id

        return VStack(alignment: .leading, spacing: 0) {
            // Row header: locale + set count chip + edit button
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("🌍").font(.system(size: 11))
                        Text(loc.locale + (loc.isPrimary ? " (primary)" : ""))
                            .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                            .foregroundStyle(theme.textPrimary)
                    }
                    if let whatsNew = loc.whatsNew, !whatsNew.isEmpty, !isEditing {
                        Text(whatsNew)
                            .font(.system(size: 11, design: theme.fontDesign))
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Fields set chip
                let count = loc.setFieldCount
                Text(count == 0 ? "Empty" : "\(count)/6")
                    .font(.system(size: 9, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(count == 0 ? BaseColors.systemOrange : BaseColors.systemGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((count == 0 ? BaseColors.systemOrange : BaseColors.systemGreen).opacity(0.15))
                    )

                if !isEditing {
                    Button {
                        draft = LocalizationDraft(from: loc)
                        saveError = nil
                        withAnimation(.easeOut(duration: 0.15)) { editingId = loc.id }
                    } label: {
                        Text("Edit")
                            .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                            .foregroundStyle(theme.accentPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.accentPrimary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(theme.accentPrimary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Edit form — expands on Edit tap
            if isEditing, var currentDraft = draft {
                VStack(alignment: .leading, spacing: 10) {
                    // What's New
                    fieldEditor(
                        label: "What's New",
                        text: Binding(
                            get: { currentDraft.whatsNew },
                            set: { currentDraft.whatsNew = $0; draft = currentDraft }
                        ),
                        isMultiline: true
                    )
                    // Description
                    fieldEditor(
                        label: "Description",
                        text: Binding(
                            get: { currentDraft.description },
                            set: { currentDraft.description = $0; draft = currentDraft }
                        ),
                        isMultiline: true
                    )
                    // Keywords
                    fieldEditor(
                        label: "Keywords",
                        text: Binding(
                            get: { currentDraft.keywords },
                            set: { currentDraft.keywords = $0; draft = currentDraft }
                        ),
                        isMultiline: false
                    )
                    // Marketing URL
                    fieldEditor(
                        label: "Marketing URL",
                        text: Binding(
                            get: { currentDraft.marketingUrl },
                            set: { currentDraft.marketingUrl = $0; draft = currentDraft }
                        ),
                        isMultiline: false
                    )
                    // Support URL
                    fieldEditor(
                        label: "Support URL",
                        text: Binding(
                            get: { currentDraft.supportUrl },
                            set: { currentDraft.supportUrl = $0; draft = currentDraft }
                        ),
                        isMultiline: false
                    )
                    // Promotional Text
                    fieldEditor(
                        label: "Promotional Text",
                        text: Binding(
                            get: { currentDraft.promotionalText },
                            set: { currentDraft.promotionalText = $0; draft = currentDraft }
                        ),
                        isMultiline: true
                    )

                    if let err = saveError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(BaseColors.systemRed)
                            Text("Failed: \(err)")
                                .font(.system(size: 10, design: theme.fontDesign))
                                .foregroundStyle(BaseColors.systemRed)
                                .lineLimit(2)
                        }
                    }

                    // Cancel / Save buttons
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                editingId = nil
                                draft = nil
                                saveError = nil
                            }
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                                .foregroundStyle(theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(theme.glassBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(theme.glassBorder, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if isSaving {
                            ProgressView().progressViewStyle(.circular).scaleEffect(0.7)
                        } else {
                            let locId = loc.id
                            let originalLoc = loc
                            let snapshotDraft = currentDraft
                            Button {
                                Task { await saveDraft(snapshotDraft, originalLoc: originalLoc, localizationId: locId) }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                                    Text("Save")
                                        .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 5).fill(theme.accentPrimary))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: isEditing)
    }

    // MARK: - Field Editor

    private func fieldEditor(label: String, text: Binding<String>, isMultiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
                .tracking(0.3)

            if isMultiline {
                TextEditor(text: text)
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(height: 56)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(theme.codeBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(theme.glassBorder, lineWidth: 1)
                            )
                    )
            } else {
                TextField("", text: text)
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(theme.codeBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(theme.glassBorder, lineWidth: 1)
                            )
                    )
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Spacer()
            Button(action: onBack) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                    Text("Close").font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(theme.glassBackground)
                        .overlay(Capsule().stroke(theme.glassBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    // MARK: - Helpers

    private var card: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 1)
            )
    }

    private func loadLocalizations() async {
        isLoading = true
        loadError = nil
        do {
            localizations = try await detailRepository.fetchLocalizations(versionId: version.id)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func saveDraft(
        _ snapshotDraft: LocalizationDraft,
        originalLoc: LocalizationSummary,
        localizationId: String
    ) async {
        savingId = localizationId
        saveError = nil
        let changed = snapshotDraft.changedFields(from: originalLoc)
        // Only save if something actually changed
        guard changed.whatsNew != nil || changed.description != nil || changed.keywords != nil
                || changed.marketingUrl != nil || changed.supportUrl != nil || changed.promotionalText != nil
        else {
            withAnimation(.easeOut(duration: 0.15)) { editingId = nil; draft = nil }
            savingId = nil
            return
        }
        do {
            try await detailRepository.updateLocalization(
                localizationId: localizationId,
                whatsNew: changed.whatsNew,
                description: changed.description,
                keywords: changed.keywords,
                marketingUrl: changed.marketingUrl,
                supportUrl: changed.supportUrl,
                promotionalText: changed.promotionalText
            )
            savingId = nil
            withAnimation(.easeOut(duration: 0.15)) { editingId = nil; draft = nil }
            await loadLocalizations()
        } catch {
            saveError = error.localizedDescription
            savingId = nil
        }
    }
}

// MARK: - Previews

#Preview("Localizations — Loaded") {
    VersionLocalizationsView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}
