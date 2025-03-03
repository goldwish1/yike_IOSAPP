import SwiftUI

struct PointsHistoryView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List {
            ForEach(dataManager.pointsRecords.sorted(by: { $0.date > $1.date })) { record in
                PointsRecordRow(record: record)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("积分记录")
    }
}

struct PointsRecordRow: View {
    let record: PointsRecord
    
    var body: some View {
        HStack {
            // 类型图标
            Image(systemName: record.isIncome ? "plus.circle.fill" : "minus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(record.isIncome ? .green : .red)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(record.isIncome ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
            
            // 记录信息
            VStack(alignment: .leading, spacing: 4) {
                Text(record.reason)
                    .font(.headline)
                
                Text(formattedDate(record.date))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 积分数量
            Text(record.isIncome ? "+\(record.absoluteAmount)" : "-\(record.absoluteAmount)")
                .font(.headline)
                .foregroundColor(record.isIncome ? .green : .red)
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 