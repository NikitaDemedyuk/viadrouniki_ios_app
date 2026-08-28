import SwiftUI

struct PointsFilterSheet: View {
    let attractionTypes: [AttractionType]
    @Binding var selectedFilterKeys: Set<PointFilterKey>
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    /// Attractions first, amenities in their own section below; the "unknown
    /// type" row sits between the two groups, matching the web app's layout.
    private var attractionCategories: [AttractionType] {
        attractionTypes.filter { !$0.isAmenity }.sortedForDisplay
    }

    private var amenityCategories: [AttractionType] {
        attractionTypes.filter(\.isAmenity).sortedForDisplay
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(attractionCategories) { row(for: $0) }
                    row(
                        title: Text("Unknown type"),
                        symbol: "questionmark",
                        color: .gray,
                        isSelected: selectedFilterKeys.contains(.unknown)
                    ) {
                        toggle(.unknown)
                    }
                }
                Section {
                    ForEach(amenityCategories) { row(for: $0) }
                }
            }
            .listStyle(.insetGrouped)
            // Pre-resolved off `appViewModel.language` — see `AppLanguage.localized(_:)`.
            .navigationTitle(appViewModel.language.localized("Filter Points"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { resetToDefault() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    selectAll()
                } label: {
                    Text("Select All")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .glassEffect(in: .rect(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(for type: AttractionType) -> some View {
        row(
            // Verbatim: the API already returns this name in the requested locale,
            // so it must not be looked up in the catalog.
            title: Text(verbatim: type.name),
            symbol: type.sfSymbolName,
            color: type.parsedColor ?? .gray,
            isSelected: selectedFilterKeys.contains(.type(type.id))
        ) {
            toggle(.type(type.id))
        }
    }

    private func row(
        title: Text,
        symbol: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.gradient)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                title
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ key: PointFilterKey) {
        if selectedFilterKeys.contains(key) {
            selectedFilterKeys.remove(key)
        } else {
            selectedFilterKeys.insert(key)
        }
    }

    private func selectAll() {
        selectedFilterKeys = attractionTypes.allFilterKeys
    }

    /// Restores the map's starting selection — everything except amenities —
    /// rather than clearing it, which would leave the user on a blank map.
    private func resetToDefault() {
        selectedFilterKeys = attractionTypes.defaultSelectedFilterKeys
    }
}
