# 忆刻应用测试指南

本文档提供了关于如何设置和运行忆刻应用测试的详细说明。

## 测试环境设置

### 前提条件

- Xcode 15.0 或更高版本
- iOS 13.0 或更高版本的模拟器或设备
- 已克隆的忆刻项目代码库

### 测试结构

测试项目分为以下几个部分：

1. **基础测试类 (YikeBaseTests)**
   - 提供通用的测试环境设置和清理功能
   - 所有测试类都应继承自此类

2. **测试辅助工具 (TestHelpers)**
   - 提供通用的测试功能和模拟对象
   - 包括文件操作、条件等待、随机数据生成等功能

3. **测试数据提供者 (TestDataProvider)**
   - 提供测试所需的示例数据
   - 包括内容数据、积分数据、学习数据等

4. **模拟对象**
   - MockUserDefaults - 模拟用户默认设置
   - MockFileManager - 模拟文件管理器
   - MockURLSession - 模拟网络请求
   - MockAVAudioPlayer - 模拟音频播放器
   - MockAVSpeechSynthesizer - 模拟语音合成器
   - MockVisionFramework - 模拟OCR识别

5. **功能测试类**
   - 服务层测试 - 测试核心服务功能
   - 数据层测试 - 测试数据管理功能
   - 视图模型测试 - 测试视图模型功能
   - 集成测试 - 测试多个组件的交互
   - 性能测试 - 测试性能指标

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
    
    func test_Feature_Condition_ExpectedResult() {
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

// 生成随机测试数据
let randomString = TestHelpers.randomString(length: 10)
let randomInt = TestHelpers.randomInt(min: 1, max: 100)
```

### 使用测试数据提供者

```swift
// 生成测试内容
let testContent = TestDataProvider.generateTestContent()

// 生成多个测试内容
let testContents = TestDataProvider.generateTestContents(count: 5)

// 生成测试积分记录
let testPointRecord = TestDataProvider.generateTestPointRecord()
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

## 测试最佳实践

1. **测试命名约定**
   - 使用格式：test_[被测功能]_[测试条件]_[预期结果]
   - 例如：test_Login_ValidCredentials_SuccessfulLogin

2. **测试结构**
   - 准备 (Arrange) - 设置测试环境和数据
   - 执行 (Act) - 执行被测试的功能
   - 验证 (Assert) - 验证结果是否符合预期

3. **测试隔离**
   - 每个测试应该独立运行，不依赖其他测试的状态
   - 使用 setUp 和 tearDown 方法确保测试环境的一致性

4. **边缘情况测试**
   - 测试空输入、无效输入和极限值
   - 测试错误处理和恢复机制

5. **异步测试**
   - 使用 XCTestExpectation 处理异步操作
   - 设置合理的超时时间

6. **性能测试**
   - 使用 measure 方法测量性能
   - 设置基准值并监控性能变化

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
