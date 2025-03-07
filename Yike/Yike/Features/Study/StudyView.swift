import SwiftUI

struct StudyView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: MemoryItem?
    
    var todayItems: [MemoryItem] {
        dataManager.memoryItems.filter { $0.needsReviewToday }
    }
    
    var inProgressItems: [MemoryItem] {
        dataManager.memoryItems.filter { $0.isInProgress && !$0.needsReviewToday }
    }
    
    var newItems: [MemoryItem] {
        dataManager.memoryItems.filter { $0.isNew }
    }
    
    var completedItems: [MemoryItem] {
        dataManager.memoryItems.filter { $0.isCompleted }
    }
    
    @State private var selectedSection: StudySection = .today
    
    enum StudySection: String, CaseIterable {
        case today = "今日待复习"
        case inProgress = "学习中"
        case new = "未开始"
        case completed = "已完成"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计概览
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatCard(title: "本周学习", value: "\(weeklyStudyHours)", unit: "小时")
                        StatCard(title: "完成项目", value: "\(completedItems.count)", unit: "个")
                    }
                    
                    HStack(spacing: 16) {
                        StatCard(title: "今日待复习", value: "\(todayItems.count)", unit: "个")
                        StatCard(title: "总学习项", value: "\(dataManager.memoryItems.count)", unit: "个")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // 分段选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(StudySection.allCases, id: \.self) { section in
                            Button(action: {
                                selectedSection = section
                            }) {
                                Text(section.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedSection == section ? Color.blue : Color(.systemGray6))
                                    )
                                    .foregroundColor(selectedSection == section ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // 内容列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedSection {
                        case .today:
                            studyItemList(items: todayItems, emptyMessage: "今日没有需要复习的内容")
                        case .inProgress:
                            studyItemList(items: inProgressItems, emptyMessage: "没有正在学习的内容")
                        case .new:
                            studyItemList(items: newItems, emptyMessage: "没有未开始的内容")
                        case .completed:
                            studyItemList(items: completedItems, emptyMessage: "还没有完成的内容")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("学习")
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
    
    private var weeklyStudyHours: Int {
        // 实际应用中应该计算真实的学习时间，这里返回一个示例值
        return 8
    }
    
    private var addButton: some View {
        NavigationLink(destination: InputSelectionView()) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .frame(width: 36, height: 36)
                .background(Color.blue)
                .clipShape(Circle())
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func studyItemList(items: [MemoryItem], emptyMessage: String) -> some View {
        if items.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.3))
                
                Text(emptyMessage)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            ForEach(items) { item in
                NavigationLink(destination: PlayerView(memoryItem: item)) {
                    StudyItemRow(item: item)
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
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StudyItemRow: View {
    let item: MemoryItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.content.prefix(30) + (item.content.count > 30 ? "..." : ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if item.isNew {
                        Text("未开始")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    } else if item.isCompleted {
                        Text("已完成")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    } else if item.needsReviewToday {
                        Text("今日复习")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    } else {
                        if let days = item.daysUntilNextReview, days > 0 {
                            Text("\(days)天后复习")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    if !item.isNew {
                        Spacer()
                        Text("进度: \(Int(item.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            NavigationLink(destination: PlayerView(memoryItem: item)) {
                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(Circle())
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