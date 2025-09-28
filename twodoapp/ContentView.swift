//
//  ContentView.swift
//  twodoapp
//
//  Created by Suwijak Thanawiboon on 28/9/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var activeSheet: ActiveSheet?

    private var sortedItems: [TodoItem] {
        store.items.sorted { a, b in
            if a.isCompleted != b.isCompleted {
                return !a.isCompleted && b.isCompleted
            }
            switch (a.dueDate, b.dueDate) {
            case let (ad?, bd?):
                return ad < bd
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
        }
    }

    private var pendingItems: [TodoItem] {
        sortedItems.filter { !$0.isCompleted }
    }

    private var completedItems: [TodoItem] {
        sortedItems.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedItems.isEmpty {
                    VStack(spacing: 12) {
                        Text("🗒️")
                            .font(.system(size: 60))
                        Text("ยังไม่มีรายการ")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("กดปุ่ม + เพื่อเพิ่มรายการใหม่")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !pendingItems.isEmpty {
                            Section(header: sectionHeader("⏳ ค้างอยู่", count: pendingItems.count)) {
                                ForEach(pendingItems) { item in
                                    todoRow(item)
                                }
                                .onDelete(perform: deletePending)
                            }
                        }

                        if !completedItems.isEmpty {
                            Section(header: sectionHeader("✅ เสร็จแล้ว", count: completedItems.count)) {
                                ForEach(completedItems) { item in
                                    todoRow(item)
                                }
                                .onDelete(perform: deleteCompleted)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("📝 2 Do App")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("เพิ่มรายการ")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                NavigationStack {
                    AddEditTodoView()
                }
            case .edit(let item):
                NavigationStack {
                    AddEditTodoView(item: item)
                }
            }
        }
    }

    @ViewBuilder
    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggleComplete(item)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.emoji)
                        .font(.title3)
                    Text(item.title)
                        .font(.body)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let status = statusEmoji(for: item.dueDate), !item.isCompleted {
                        Text(status)
                            .font(.body)
                            .accessibilityHidden(true)
                    }
                }

                if let due = item.dueDate {
                    HStack(spacing: 6) {
                        Text(statusEmoji(for: due) ?? "🗓️")
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text(due, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(due, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            activeSheet = .edit(item)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(item)
            } label: {
                Label("ลบ 🗑️", systemImage: "trash")
            }

            Button {
                activeSheet = .edit(item)
            } label: {
                Label("แก้ไข ✏️", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .padding(.vertical, 4)
    }

    private func deletePending(at offsets: IndexSet) {
        let idsToDelete = offsets.map { pendingItems[$0].id }
        store.delete(where: { idsToDelete.contains($0.id) })
    }

    private func deleteCompleted(at offsets: IndexSet) {
        let idsToDelete = offsets.map { completedItems[$0].id }
        store.delete(where: { idsToDelete.contains($0.id) })
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .textCase(nil)
    }

    private func statusEmoji(for dueDate: Date?) -> String? {
        guard let dueDate else { return nil }
        let now = Date()
        if dueDate < now {
            return "🔥" // เลยกำหนด
        }
        if let soon = Calendar.current.date(byAdding: .hour, value: 24, to: now), dueDate <= soon {
            return "⏰" // ภายใน 24 ชม.
        }
        return "📅" // อนาคต
    }

    private enum ActiveSheet: Identifiable {
        case add
        case edit(TodoItem)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let item):
                return "edit-\(item.id.uuidString)"
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore(preview: true))
}
