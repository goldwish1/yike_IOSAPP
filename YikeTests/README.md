# Yike 应用测试指南

本文档提供了关于如何设置和运行 Yike 应用测试的详细说明。

## 测试环境设置

### 前提条件

- Xcode 15.0 或更高版本
- iOS 17.0 或更高版本的模拟器或设备
- 已克隆的 Yike 项目代码库

### 测试结构

测试项目分为以下几个部分：

1. **基础测试类 (YikeBaseTests)**
   - 提供通用的测试环境设置和清理功能
   - 所有测试类都应继承自此类

2. **测试辅助工具 (TestHelpers)**
   - 提供通用的测试功能和模拟对象
   - 包括文件操作、条件等待、模拟延迟等功能

3. **模拟对象**
   - MockUserDefaults - 模拟用户默认设置
   - MockFileManager - 模拟文件管理器
   - MockAVAudioPlayer - 模拟音频播放器

4. **测试数据提供者 (TestDataProvider)**
   - 提供测试所需的示例数据

5. **功能测试类**
   - AudioPlayerServiceTests - 测试音频播放服务
   - PointsConsumptionTests - 测试点数消费功能
   - PointsIntegrationTests - 测试点数集成功能

## 运行测试

### 使用 Xcode 运行测试

1. 打开 Yike.xcodeproj 项目
2. 选择 "Product" > "Scheme" > "Edit Scheme..."
3. 在左侧选择 "Test"
4. 确保已选择 "Yike.xctestplan"
5. 点击 "Close"
6. 按下 Command+U 或选择 "Product" > "Test" 运行所有测试

### 运行特定测试类或方法

1. 在 Xcode 的测试导航器中找到要运行的测试类或方法
2. 点击测试类或方法旁边的运行按钮
3. 或者，在测试类或方法上右键点击，选择 "Test"

### 查看测试结果

1. 测试完成后，Xcode 会显示测试结果
2. 绿色对勾表示测试通过，红色 X 表示测试失败
3. 点击失败的测试可以查看详细错误信息

## 添加新测试

### 添加新的测试类

1. 在 YikeTests 目标中创建新的 Swift 文件
2. 导入必要的框架：

```swift
import XCTest
@testable import Yike
```

3. 创建继承自 YikeBaseTests 的测试类：

```swift
class NewFeatureTests: YikeBaseTests {
    
    override func setUp() {
        super.setUp()
        // 设置特定的测试环境
    }
    
    override func tearDown() {
        // 清理特定的测试环境
        super.tearDown()
    }
    
    func testNewFeature() {
        // 测试代码
        XCTAssertTrue(true, "测试应该通过")
    }
}
```

### 使用模拟对象

```swift
// 创建模拟用户默认设置
let mockUserDefaults = MockUserDefaults()

// 使用模拟对象
someService.userDefaults = mockUserDefaults

// 验证结果
XCTAssertEqual(mockUserDefaults.integer(forKey: "someKey"), 42)
```

### 使用测试辅助工具

```swift
// 创建临时文件
let data = "测试数据".data(using: .utf8)!
let url = TestHelpers.createTemporaryFile(withName: "test.txt", data: data)

// 等待条件满足
let success = TestHelpers.waitForCondition {
    return someAsyncOperation.isCompleted
}
XCTAssertTrue(success, "操作应该完成")

// 模拟延迟
TestHelpers.delay(0.5) {
    // 延迟执行的代码
}
```

## 测试覆盖率

### 启用代码覆盖率

1. 在 Xcode 中选择 "Product" > "Scheme" > "Edit Scheme..."
2. 在左侧选择 "Test"
3. 在 "Options" 选项卡中，勾选 "Code Coverage"
4. 选择要收集覆盖率的目标
5. 点击 "Close"

### 查看覆盖率报告

1. 运行测试后，选择 "Product" > "Show Coverage"
2. Xcode 会显示代码覆盖率报告
3. 绿色表示已覆盖的代码，红色表示未覆盖的代码

## 持续集成

本项目已配置为使用 GitHub Actions 进行持续集成。每次推送代码或创建拉取请求时，都会自动运行测试。

### 本地验证 CI 配置

在推送代码前，可以使用以下命令在本地运行测试：

```bash
xcodebuild test -project Yike.xcodeproj -scheme Yike -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' -testPlan Yike
```

## 故障排除

### 常见问题

1. **测试无法编译**
   - 确保已导入必要的框架
   - 检查是否有语法错误

2. **测试失败**
   - 检查错误信息
   - 确保测试环境正确设置
   - 验证测试数据是否有效

3. **测试超时**
   - 增加等待超时时间
   - 检查异步操作是否正确完成

### 获取帮助

如有问题，请联系项目维护者或在项目仓库中创建 Issue。 