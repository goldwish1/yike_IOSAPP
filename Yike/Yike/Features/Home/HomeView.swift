import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: MemoryItem?
    
    var todayItems: [MemoryItem] {
        dataManager.memoryItems.filter { item in
            item.needsReviewToday || (item.isNew && !item.isCompleted)
        }
    }
    
    var recentItems: [MemoryItem] {
        dataManager.memoryItems
            .filter { !$0.isCompleted }
            .sorted { $0.lastReviewDate ?? Date.distantPast > $1.lastReviewDate ?? Date.distantPast }
            .prefix(3)
            .map { $0 }
    }
    
    var completedTodayCount: Int {
        dataManager.memoryItems.filter { item in
            guard let lastReview = item.lastReviewDate else { return false }
            return Calendar.current.isDateInToday(lastReview) && item.needsReviewToday == false
        }.count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 今日任务
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("今日任务")
                                .font(.headline)
                            Spacer()
                            Text("已完成 \(completedTodayCount)/\(todayItems.count + completedTodayCount)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        ForEach(todayItems) { item in
                            NavigationLink(destination: PlayerView(memoryItems: todayItems, initialIndex: todayItems.firstIndex(of: item) ?? 0)) {
                                MemoryItemCard(item: item)
                                    .contextMenu {
                                        Button(role: .destructive, action: {
                                            itemToDelete = item
                                            showingDeleteAlert = true
                                        }) {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            itemToDelete = item
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if todayItems.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Text("今日任务已完成！")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    
                    // 最近添加
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近添加")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: StudyView()) {
                                Text("查看全部")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        ForEach(recentItems) { item in
                            NavigationLink(destination: PlayerView(memoryItems: recentItems, initialIndex: recentItems.firstIndex(of: item) ?? 0)) {
                                MemoryItemCard(item: item)
                                    .contextMenu {
                                        Button(role: .destructive, action: {
                                            itemToDelete = item
                                            showingDeleteAlert = true
                                        }) {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            itemToDelete = item
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("忆刻")
            .navigationBarItems(trailing: addButton)
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {
                    itemToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let item = itemToDelete {
                        dataManager.deleteMemoryItem(item)
                        itemToDelete = nil
                    }
                }
            } message: {
                Text("确定要删除「\(itemToDelete?.title ?? "")」吗？此操作不可撤销。")
            }
        }
    }
    
    var addButton: some View {
        NavigationLink(destination: InputSelectionView()) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .frame(width: 36, height: 36)
                .background(Color.blue)
                .clipShape(Circle())
                .foregroundColor(.white)
        }
    }
}

struct MemoryItemCard: View {
    let item: MemoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                
                if item.needsReviewToday {
                    Text("待复习")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                } else if item.isNew {
                    Text("新内容")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            
            Text(item.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.bottom, 4)
            
            HStack {
                if item.isNew {
                    Text("刚刚添加")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text("记忆进度: \(Int(item.progress * 100))%")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: PlayerView(memoryItems: [item], initialIndex: 0)) {
                    Image(systemName: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
} 