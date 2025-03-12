import XCTest

class PointsUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // 确保我们在首页
        navigateToHome()
    }
    
    // MARK: - 测试用例
    
    /// 测试积分不足时的提示界面
    func testInsufficientPointsAlert() throws {
        // 导航到设置页面
        app.tabBars.buttons["设置"].tap()
        
        // 导航到积分中心
        app.tables.cells["积分中心"].tap()
        
        // 检查当前积分
        let pointsText = app.staticTexts.matching(identifier: "pointsValue").firstMatch.label
        let currentPoints = Int(pointsText) ?? 0
        
        // 如果积分大于等于5，则跳过测试
        guard currentPoints < 5 else {
            XCTSkip("当前积分足够，无法测试积分不足场景")
            return
        }
        
        // 返回首页
        app.navigationBars.buttons["设置"].tap()
        app.tabBars.buttons["首页"].tap()
        
        // 点击第一个记忆项目
        app.scrollViews.otherElements.cells.firstMatch.tap()
        
        // 启用在线语音
        if app.switches["useApiVoiceSwitch"].exists && !app.switches["useApiVoiceSwitch"].isSelected {
            app.switches["useApiVoiceSwitch"].tap()
        }
        
        // 点击播放按钮
        app.buttons["playButton"].tap()
        
        // 验证是否显示积分不足提示
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "积分不足")).firstMatch.exists, "应该显示积分不足提示")
    }
    
    /// 测试积分消耗后余额显示
    func testPointsBalanceAfterConsumption() throws {
        // 导航到设置页面
        app.tabBars.buttons["设置"].tap()
        
        // 导航到积分中心
        app.tables.cells["积分中心"].tap()
        
        // 检查当前积分
        let pointsText = app.staticTexts.matching(identifier: "pointsValue").firstMatch.label
        let currentPoints = Int(pointsText) ?? 0
        
        // 如果积分小于5，则跳过测试
        guard currentPoints >= 5 else {
            XCTSkip("当前积分不足，无法测试积分消耗场景")
            return
        }
        
        // 返回首页
        app.navigationBars.buttons["设置"].tap()
        app.tabBars.buttons["首页"].tap()
        
        // 点击第一个记忆项目
        app.scrollViews.otherElements.cells.firstMatch.tap()
        
        // 启用在线语音
        if app.switches["useApiVoiceSwitch"].exists && !app.switches["useApiVoiceSwitch"].isSelected {
            app.switches["useApiVoiceSwitch"].tap()
        }
        
        // 点击播放按钮
        app.buttons["playButton"].tap()
        
        // 等待播放完成
        sleep(3)
        
        // 返回首页
        app.navigationBars.buttons.firstMatch.tap()
        
        // 导航到设置页面
        app.tabBars.buttons["设置"].tap()
        
        // 导航到积分中心
        app.tables.cells["积分中心"].tap()
        
        // 检查更新后的积分
        let newPointsText = app.staticTexts.matching(identifier: "pointsValue").firstMatch.label
        let newPoints = Int(newPointsText) ?? 0
        
        // 验证积分是否减少
        XCTAssertEqual(newPoints, currentPoints - 5, "积分应该减少5")
    }
    
    /// 测试积分记录显示
    func testPointsRecordDisplay() throws {
        // 导航到设置页面
        app.tabBars.buttons["设置"].tap()
        
        // 导航到积分中心
        app.tables.cells["积分中心"].tap()
        
        // 点击查看明细
        app.buttons["查看明细"].tap()
        
        // 验证积分记录页面标题
        XCTAssertTrue(app.navigationBars["积分记录"].exists, "应该显示积分记录页面")
        
        // 验证是否显示积分记录
        XCTAssertTrue(app.tables.cells.count > 0, "应该显示积分记录")
    }
    
    // MARK: - 辅助方法
    
    /// 导航到首页
    private func navigateToHome() {
        // 如果存在标签栏，点击首页标签
        if app.tabBars.buttons["首页"].exists {
            app.tabBars.buttons["首页"].tap()
            return
        }
        
        // 如果在其他页面，尝试返回首页
        while app.navigationBars.buttons["返回"].exists {
            app.navigationBars.buttons["返回"].tap()
        }
    }
} 