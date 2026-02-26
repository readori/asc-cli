import SwiftUI
import AppKit
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
        whatsNew        = loc.whatsNew        ?? ""
        description     = loc.description     ?? ""
        keywords        = loc.keywords        ?? ""
        marketingUrl    = loc.marketingUrl    ?? ""
        supportUrl      = loc.supportUrl      ?? ""
        promotionalText = loc.promotionalText ?? ""
    }

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

    var hasAnyChange: Bool {
        // Compared against empty original — caller checks against actual original
        false // real check done via changedFields()
    }
}

// MARK: - View

/// Screen 7 — locale tab picker + focused What's New editor.
/// Mental model: "I'm writing release notes — pick a language, fill in What's New, save."
struct VersionLocalizationsView: View {
    let version: ASCVersion
    let detailRepository: any VersionDetailRepository
    let onBack: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var localizations: [LocalizationSummary] = []
    @State private var isLoading = true
    @State private var loadError: String? = nil

    // Active locale
    @State private var selectedId: String? = nil

    // Edit state for the active locale
    @State private var draft: LocalizationDraft? = nil
    @State private var isSaving = false
    @State private var saveError: String? = nil
    @State private var showMoreFields = false
    @State private var copiedCmd = false

    private var selectedLocale: LocalizationSummary? {
        guard let id = selectedId else { return localizations.first }
        return localizations.first(where: { $0.id == id }) ?? localizations.first
    }

    private var currentDraft: LocalizationDraft {
        draft ?? LocalizationDraft(from: selectedLocale ?? .empty)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if localizations.isEmpty {
                emptyView
            } else {
                localeTabs
                Divider().background(theme.dividerColor)
                editorScroll
                if let loc = selectedLocale {
                    actionBar(for: loc)
                }
            }
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
                    Text(version.versionString)
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

            Color.clear.frame(width: 80, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Locale Tabs

    private var localeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(localizations) { loc in
                    Button {
                        switchLocale(to: loc)
                    } label: {
                        HStack(spacing: 4) {
                            Text(loc.locale)
                                .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                            if loc.isPrimary {
                                Text("★")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(BaseColors.systemPurple.opacity(0.8))
                            }
                        }
                        .foregroundStyle(isSelected(loc) ? theme.textPrimary : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isSelected(loc)
                                      ? BaseColors.systemPurple.opacity(0.15)
                                      : theme.glassBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected(loc)
                                                ? BaseColors.systemPurple.opacity(0.35)
                                                : theme.glassBorder, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func isSelected(_ loc: LocalizationSummary) -> Bool {
        loc.id == (selectedId ?? localizations.first?.id)
    }

    // MARK: - Editor scroll

    private var editorScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let loc = selectedLocale {
                    whatsNewField(loc: loc)
                    moreFieldsSection(loc: loc)
                    if let err = saveError {
                        saveErrorBanner(err)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
        .frame(maxHeight: 340)
    }

    // MARK: - What's New (primary field)

    private func whatsNewField(loc: LocalizationSummary) -> some View {
        let isEmpty = currentDraft.whatsNew.isEmpty
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("WHAT'S NEW")
                    .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(isEmpty ? BaseColors.systemOrange : theme.textTertiary)
                    .tracking(0.6)
                if isEmpty {
                    Text("— not set")
                        .font(.system(size: 10, design: theme.fontDesign))
                        .foregroundStyle(BaseColors.systemOrange.opacity(0.7))
                }
            }

            TextEditor(text: Binding(
                get: { currentDraft.whatsNew },
                set: { val in
                    var d = currentDraft; d.whatsNew = val; draft = d
                }
            ))
            .font(.system(size: 13, design: theme.fontDesign))
            .foregroundStyle(theme.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(height: 88)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEmpty
                          ? BaseColors.systemOrange.opacity(0.05)
                          : theme.codeBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isEmpty
                                    ? BaseColors.systemOrange.opacity(0.35)
                                    : theme.glassBorder, lineWidth: 1)
                    )
            )

            Text("Shown to users in the App Store Updates tab")
                .font(.system(size: 10, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
        }
    }

    // MARK: - More Fields (collapsed)

    private func moreFieldsSection(loc: LocalizationSummary) -> some View {
        let setCount = [loc.description, loc.keywords, loc.marketingUrl,
                        loc.supportUrl, loc.promotionalText].compactMap(\.self).count

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) { showMoreFields.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text("🔤")
                        .font(.system(size: 13))
                    Text("Description · Keywords · URLs")
                        .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text("\(setCount)/5")
                        .font(.system(size: 9, weight: .bold, design: theme.fontDesign))
                        .foregroundStyle(setCount > 0 ? BaseColors.systemGreen : theme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill((setCount > 0 ? BaseColors.systemGreen : theme.textTertiary).opacity(0.15))
                        )
                    Image(systemName: showMoreFields ? "chevron.up" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.glassBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if showMoreFields {
                VStack(alignment: .leading, spacing: 10) {
                    inlineField(label: "Description", multiline: true,
                                hint: "Min 10 chars",
                                validationError: descriptionError,
                                get: { currentDraft.description },
                                set: { val in var d = currentDraft; d.description = val; draft = d })
                    inlineField(label: "Keywords", multiline: false,
                                hint: "Comma-separated",
                                get: { currentDraft.keywords },
                                set: { val in var d = currentDraft; d.keywords = val; draft = d })
                    inlineField(label: "Marketing URL", multiline: false,
                                hint: "https://",
                                validationError: urlError(currentDraft.marketingUrl),
                                get: { currentDraft.marketingUrl },
                                set: { val in var d = currentDraft; d.marketingUrl = val; draft = d })
                    inlineField(label: "Support URL", multiline: false,
                                hint: "https://",
                                validationError: urlError(currentDraft.supportUrl),
                                get: { currentDraft.supportUrl },
                                set: { val in var d = currentDraft; d.supportUrl = val; draft = d })
                    inlineField(label: "Promotional Text", multiline: true,
                                get: { currentDraft.promotionalText },
                                set: { val in var d = currentDraft; d.promotionalText = val; draft = d })
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func inlineField(
        label: String, multiline: Bool,
        hint: String? = nil, validationError: String? = nil,
        get: @escaping () -> String,
        set: @escaping (String) -> Void
    ) -> some View {
        let hasError = validationError != nil
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(hasError ? BaseColors.systemRed : theme.textTertiary)
                .tracking(0.3)

            if multiline {
                TextEditor(text: Binding(get: get, set: set))
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(height: 54)
                    .padding(4)
                    .background(fieldBackground(hasError: hasError))
            } else {
                TextField("", text: Binding(get: get, set: set))
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(fieldBackground(hasError: hasError))
            }

            if let err = validationError {
                Text(err).font(.system(size: 9)).foregroundStyle(BaseColors.systemRed)
            } else if let hint {
                Text(hint).font(.system(size: 9)).foregroundStyle(theme.textTertiary)
            }
        }
    }

    private func fieldBackground(hasError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(hasError ? BaseColors.systemRed.opacity(0.07) : theme.codeBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(hasError ? BaseColors.systemRed.opacity(0.4) : theme.glassBorder, lineWidth: 1)
            )
    }

    // MARK: - Save Error Banner

    private func saveErrorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(BaseColors.systemRed)
            Text("Failed: \(error)")
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(BaseColors.systemRed)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BaseColors.systemRed.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BaseColors.systemRed.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Action Bar

    private func actionBar(for loc: LocalizationSummary) -> some View {
        let changed = currentDraft.changedFields(from: loc)
        let hasChanges = changed.whatsNew != nil || changed.description != nil
            || changed.keywords != nil || changed.marketingUrl != nil
            || changed.supportUrl != nil || changed.promotionalText != nil
        let hasErrors = hasValidationErrors
        let cmd = buildCLICommand(draft: currentDraft, loc: loc)

        return HStack(spacing: 8) {
            if hasChanges {
                Button {
                    switchLocale(to: loc, force: true) // discard
                } label: {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(theme.glassBackground)
                            .overlay(Capsule().stroke(theme.glassBorder, lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let cmd {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    withAnimation { copiedCmd = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copiedCmd = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedCmd ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9, weight: .semibold))
                        Text(copiedCmd ? "Copied!" : "Copy Cmd")
                            .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                    }
                    .foregroundStyle(copiedCmd ? theme.statusLive : theme.accentPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((copiedCmd ? theme.statusLive : theme.accentPrimary).opacity(0.1))
                            .overlay(Capsule().stroke((copiedCmd ? theme.statusLive : theme.accentPrimary).opacity(0.25), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: copiedCmd)
            }

            if isSaving {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.75)
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
                            .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(hasErrors || !hasChanges
                                  ? Color.gray.opacity(0.3)
                                  : BaseColors.systemPurple)
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasErrors || !hasChanges)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(
            Rectangle()
                .fill(theme.backgroundColor)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(theme.dividerColor), alignment: .top)
        )
    }

    // MARK: - State transitions

    private func switchLocale(to loc: LocalizationSummary, force: Bool = false) {
        withAnimation(.easeOut(duration: 0.15)) {
            selectedId = loc.id
            draft = nil
            saveError = nil
            copiedCmd = false
            if !force { showMoreFields = false }
        }
    }

    // MARK: - Loading / empty / error states

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
        .padding(.vertical, 48)
    }

    private func errorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(BaseColors.systemOrange)
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(BaseColors.systemOrange.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BaseColors.systemOrange.opacity(0.25), lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    private var emptyView: some View {
        Text("No localizations found")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 48)
    }

    // MARK: - Validation

    private var descriptionError: String? {
        let v = currentDraft.description
        if !v.isEmpty && v.count < 10 { return "At least 10 characters required" }
        return nil
    }

    private func urlError(_ value: String) -> String? {
        if !value.isEmpty && !value.hasPrefix("https://") && !value.hasPrefix("http://") {
            return "Must start with https://"
        }
        return nil
    }

    private var hasValidationErrors: Bool {
        descriptionError != nil
            || urlError(currentDraft.marketingUrl) != nil
            || urlError(currentDraft.supportUrl) != nil
    }

    // MARK: - CLI Command

    private func buildCLICommand(draft: LocalizationDraft, loc: LocalizationSummary) -> String? {
        let changed = draft.changedFields(from: loc)
        var parts: [String] = ["asc version-localizations update --localization-id \(loc.id)"]
        if let v = changed.whatsNew        { parts.append("--whats-new \(shellQuote(v))") }
        if let v = changed.description     { parts.append("--description \(shellQuote(v))") }
        if let v = changed.keywords        { parts.append("--keywords \(shellQuote(v))") }
        if let v = changed.marketingUrl    { parts.append("--marketing-url \(shellQuote(v))") }
        if let v = changed.supportUrl      { parts.append("--support-url \(shellQuote(v))") }
        if let v = changed.promotionalText { parts.append("--promotional-text \(shellQuote(v))") }
        guard parts.count > 1 else { return nil }
        return parts.joined(separator: " \\\n  ")
    }

    private func shellQuote(_ s: String) -> String {
        "'\(s.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    // MARK: - Network

    private func loadLocalizations() async {
        isLoading = true
        loadError = nil
        do {
            localizations = try await detailRepository.fetchLocalizations(versionId: version.id)
            selectedId = localizations.first?.id
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
        isSaving = true
        saveError = nil
        let changed = snapshotDraft.changedFields(from: originalLoc)
        guard changed.whatsNew != nil || changed.description != nil || changed.keywords != nil
                || changed.marketingUrl != nil || changed.supportUrl != nil || changed.promotionalText != nil
        else {
            withAnimation(.easeOut(duration: 0.15)) { draft = nil }
            isSaving = false
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
            if let idx = localizations.firstIndex(where: { $0.id == localizationId }) {
                let orig = localizations[idx]
                func apply(_ c: String?, _ o: String?) -> String? {
                    guard let c else { return o }
                    return c.isEmpty ? nil : c
                }
                localizations[idx] = LocalizationSummary(
                    id: orig.id, locale: orig.locale, isPrimary: orig.isPrimary,
                    whatsNew: apply(changed.whatsNew, orig.whatsNew),
                    description: apply(changed.description, orig.description),
                    keywords: apply(changed.keywords, orig.keywords),
                    marketingUrl: apply(changed.marketingUrl, orig.marketingUrl),
                    supportUrl: apply(changed.supportUrl, orig.supportUrl),
                    promotionalText: apply(changed.promotionalText, orig.promotionalText)
                )
            }
            withAnimation(.easeOut(duration: 0.15)) { draft = nil }
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - LocalizationSummary convenience

private extension LocalizationSummary {
    static var empty: LocalizationSummary {
        LocalizationSummary(id: "", locale: "", isPrimary: false)
    }
}

// MARK: - Previews

#Preview("Localizations — Loaded (en-US selected)") {
    VersionLocalizationsView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

#Preview("Localizations — Loaded (light)") {
    VersionLocalizationsView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "light")
}
