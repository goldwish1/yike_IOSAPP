import SwiftUI

struct PointsCenterView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingRechargeSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 积分卡片
                ZStack(alignment: .bottomLeading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 180)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // 装饰图形
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .offset(x: -30, y: 40)
                    
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .offset(x: 260, y: -50)
                    
                    // 内容
                    VStack(alignment: .leading, spacing: 16) {
                        Text("我的积分")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(dataManager.points)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack {
                            NavigationLink(destination: PointsHistoryView()) {
                                Text("查看明细")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(16)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal)
                
                // 可用服务
                VStack(alignment: .leading, spacing: 16) {
                    Text("可用服务")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // OCR识别
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("拍照识别")
                                    .font(.headline)
                                
                                Text("支持多种文本格式")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("10积分/次")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Button(action: {}) {
                                    Text("使用")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
                
                // 温馨提示
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("温馨提示")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    
                    Text("• 新用户注册即送100积分\n• 日常对话完全免费，无需消耗积分\n• 拍照识别每次消耗10积分\n• 积分永久有效，充值不过期")
                        .font(.subheadline)
                        .lineSpacing(6)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 充值按钮
                Button(action: {
                    showingRechargeSheet = true
                }) {
                    Text("充值积分")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("积分中心")
        .sheet(isPresented: $showingRechargeSheet) {
            PointsRechargeView()
        }
    }
}

struct PointsHistoryView: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var recordsByMonth: [String: [PointsRecord]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月"
        
        var result: [String: [PointsRecord]] = [:]
        
        for record in dataManager.pointsRecords.sorted(by: { $0.date > $1.date }) {
            let monthKey = dateFormatter.string(from: record.date)
            if result[monthKey] == nil {
                result[monthKey] = []
            }
            result[monthKey]?.append(record)
        }
        
        return result
    }
    
    var body: some View {
        List {
            ForEach(Array(recordsByMonth.keys.sorted(by: >)), id: \.self) { month in
                Section(header: Text(month)) {
                    ForEach(recordsByMonth[month] ?? []) { record in
                        HStack {
                            // 积分类型图标
                            Image(systemName: iconForRecord(record))
                                .font(.system(size: 18))
                                .foregroundColor(colorForRecord(record))
                                .frame(width: 36, height: 36)
                                .background(colorForRecord(record).opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.reason)
                                    .font(.headline)
                                
                                Text(formattedDate(record.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(record.isIncome ? "+\(record.absoluteAmount)" : "-\(record.absoluteAmount)")
                                .font(.headline)
                                .foregroundColor(record.isIncome ? .green : .red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("积分记录")
    }
    
    private func iconForRecord(_ record: PointsRecord) -> String {
        if record.reason.contains("OCR") || record.reason.contains("识别") {
            return "text.viewfinder"
        } else if record.reason.contains("充值") {
            return "creditcard.fill"
        } else if record.reason.contains("奖励") {
            return "gift.fill"
        } else {
            return "circle.fill"
        }
    }
    
    private func colorForRecord(_ record: PointsRecord) -> Color {
        if record.isIncome {
            return .green
        } else {
            return .red
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

struct PointsRechargeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedPackage = 1
    @State private var showingPurchaseAlert = false
    
    let packages = [
        (points: 100, price: 3),
        (points: 300, price: 8),
        (points: 600, price: 15),
        (points: 1000, price: 20)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("选择充值套餐")
                        .font(.headline)
                    
                    Text("不同套餐有不同优惠，充值金额越多优惠越大")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 套餐选择
                    VStack(spacing: 16) {
                        ForEach(0..<packages.count, id: \.self) { index in
                            Button(action: {
                                selectedPackage = index
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(packages[index].points)积分")
                                            .font(.headline)
                                        
                                        if index == 2 {
                                            Text("最受欢迎")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("¥\(packages[index].price)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPackage == index ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedPackage == index ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 购买按钮
                    Button(action: {
                        showingPurchaseAlert = true
                    }) {
                        Text("购买 ¥\(packages[selectedPackage].price)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal)
                    
                    Text("点击"购买"，将通过 Apple 支付进行扣款")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
            }
            .navigationTitle("积分充值")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingPurchaseAlert) {
                Alert(
                    title: Text("购买成功"),
                    message: Text("您已成功购买\(packages[selectedPackage].points)积分"),
                    dismissButton: .default(Text("确定")) {
                        // 模拟购买成功，添加积分
                        dataManager.addPoints(
                            packages[selectedPackage].points,
                            reason: "充值积分"
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
} 