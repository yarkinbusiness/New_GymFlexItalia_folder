//
//  FAQView.swift
//  Gym Flex Italia
//
//  Frequently Asked Questions view with expandable answers.
//

import SwiftUI

/// FAQ list view with expandable answers
struct FAQView: View {
    
    @State private var expandedItemId: String?
    
    private let items = FAQStore.shared.items
    
    var body: some View {
        List {
            ForEach(items) { item in
                FAQRowView(
                    item: item,
                    isExpanded: expandedItemId == item.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedItemId == item.id {
                                expandedItemId = nil
                            } else {
                                expandedItemId = item.id
                            }
                        }
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Individual FAQ row with expand/collapse
struct FAQRowView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Question Row
            Button(action: onTap) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    Text(item.question)
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Answer (shown when expanded)
            if isExpanded {
                Text(item.answer)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}
