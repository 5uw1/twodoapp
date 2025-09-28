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
                    .padding(20)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !pendingItems.isEmpty {
                            Section(header: sectionHeader("⏳ ค้างอยู่", count: pendingItems.count)) {
                                ForEach(pendingItems) { item in
                                    todoRow(item)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                                .onDelete(perform: deletePending)
                            }
                        }

                        if !completedItems.isEmpty {
                            Section(header: sectionHeader("✅ เสร็จแล้ว", count: completedItems.count)) {
                                ForEach(completedItems) { item in
                                    todoRow(item)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                                .onDelete(perform: deleteCompleted)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    #if os(macOS)
                    .listStyle(.inset)
                    .listSectionSpacing(.compact)
                    .padding(.top, -6)
                    #else
                    .listStyle(.insetGrouped)
                    #endif
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
        .background(LiquidGlassBackground().ignoresSafeArea())
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
        .padding(12)
        .cardBackground()
        .contentShape(Rectangle())
        .id(item.id) // คง identity ให้คงที่ระหว่างสไลด์
        .onTapGesture {
            activeSheet = .edit(item)
        }
        // ปิด full-swipe เพื่อไม่ให้ลบทันทีขณะสไลด์
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // หน่วงเล็กน้อยให้ระบบปิดการกวาดก่อน แล้วค่อยลบ
                deferMutation {
                    store.delete(item)
                }
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel("ลบ")

            Button {
                deferMutation {
                    activeSheet = .edit(item)
                }
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.blue)
            .accessibilityLabel("แก้ไข")
        }
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func statusEmoji(for dueDate: Date?) -> String? {
        guard let dueDate else { return nil }
        let now = Date()
        if dueDate < now {
            return "🔥"
        }
        if let soon = Calendar.current.date(byAdding: .hour, value: 24, to: now), dueDate <= soon {
            return "⏰"
        }
        return "📅"
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

private struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(colorScheme == .dark ? 0.35 : 0.5),
                    Color.purple.opacity(colorScheme == .dark ? 0.35 : 0.5),
                    Color.pink.opacity(colorScheme == .dark ? 0.35 : 0.5),
                    Color.cyan.opacity(colorScheme == .dark ? 0.35 : 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.cyan.opacity(0.35))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -140, y: -200)

            Circle()
                .fill(Color.pink.opacity(0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 160, y: -120)

            Circle()
                .fill(Color.purple.opacity(0.35))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 120, y: 260)
        }
        .ignoresSafeArea()
    }
}

// พื้นหลังการ์ดแบบเสถียร ลดปัญหา mask ของ UIKit ระหว่างสไลด์
private struct CardBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(
                color: (colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.08)),
                radius: (colorScheme == .dark ? 16 : 8),
                x: 0,
                y: (colorScheme == .dark ? 8 : 4)
            )
    }
}

private extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        background(CardBackground(cornerRadius: cornerRadius))
    }

    func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        background(CardBackground(cornerRadius: cornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // หน่วงการเปลี่ยนแปลงแหล่งข้อมูลหลังจากปุ่มกวาดถูกกด
    func deferMutation(_ block: @escaping () -> Void) {
        Task {
            // หน่วง ~120ms ให้ UIKit ปิดการกวาด/ทำ state transition ให้เรียบร้อยก่อน
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    block()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore(preview: true))
}
