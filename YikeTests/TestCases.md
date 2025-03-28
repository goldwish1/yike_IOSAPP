# 忆刻应用冒烟测试用例

本文档详细描述忆刻应用冒烟测试的具体测试用例，按功能模块进行组织。

## 1. 基础导航和UI测试

### TC-1.1: 应用启动和主页加载

**优先级**: 高  
**测试类型**: UI测试

**测试步骤**:
1. 启动应用
2. 等待主页完全加载

**预期结果**:
1. 应用成功启动，无崩溃或异常
2. 主页正确显示，包含首页、学习和设置标签
3. 如有内容，内容列表应正确显示
4. 添加新内容按钮可见且可点击

### TC-1.2: 标签页切换

**优先级**: 高  
**测试类型**: UI测试

**测试步骤**:
1. 在主页点击"学习"标签
2. 点击"设置"标签
3. 返回"首页"标签

**预期结果**:
1. 能正确切换到各个标签页
2. 各标签页内容正确加载
3. 导航过程中无卡顿或崩溃

## 2. 内容管理功能测试

### TC-2.1: 创建新内容（手动输入）

**优先级**: 高  
**测试类型**: UI测试

**测试步骤**:
1. 在首页点击"添加新内容"按钮
2. 选择"手动输入"选项
3. 输入标题"测试标题"
4. 输入内容"这是一段测试内容"
5. 点击"下一步"按钮
6. 在预览编辑页面检查并确认标题和内容
7. 点击"保存"按钮

**预期结果**:
1. 成功保存内容并返回首页
2. 新创建的内容显示在列表中
3. 标题和内容显示正确

### TC-2.2: 内容删除功能

**优先级**: 中  
**测试类型**: UI测试

**测试步骤**:
1. 在首页长按任一内容项
2. 在弹出的菜单中选择"删除"
3. 在确认对话框中选择"确认"

**预期结果**:
1. 选中的内容被成功删除
2. 内容列表更新，不再显示已删除内容
3. 操作过程中无应用崩溃

## 3. 播放功能测试

### TC-3.1: 本地语音播放

**优先级**: 高  
**测试类型**: 混合（单元测试+UI测试）

**测试步骤**:
1. 在首页选择任一内容项
2. 确保设置中选择"本地语音"
3. 点击"播放"按钮
4. 等待5秒钟
5. 点击"暂停"按钮

**预期结果**:
1. 播放按钮点击后变为暂停按钮
2. 语音正常播放内容文本
3. 暂停按钮点击后播放停止
4. 播放进度条正确显示

### TC-3.2: 在线语音播放

**优先级**: 高  
**测试类型**: 混合（单元测试+UI测试）

**测试步骤**:
1. 在首页选择任一内容项
2. 进入播放设置页面
3. 开启"使用在线语音"选项
4. 返回播放页面
5. 点击"播放"按钮
6. 等待5秒钟
7. 点击"暂停"按钮

**预期结果**:
1. 在线语音选项成功切换
2. 播放按钮点击后开始播放
3. 语音正常播放内容文本
4. 暂停按钮点击后播放停止
5. 积分正确扣除（如设置为消费积分）

### TC-3.3: 播放速度调节

**优先级**: 中  
**测试类型**: UI测试

**测试步骤**:
1. 在播放页面点击语速按钮
2. 选择"1.5x"速度
3. 点击"播放"按钮
4. 等待5秒钟

**预期结果**:
1. 语速设置成功更改为1.5x
2. 播放语速明显变快
3. 语速设置按钮显示当前速度

## 4. 积分系统测试

### TC-4.1: 积分余额显示

**优先级**: 高  
**测试类型**: 单元测试

**测试步骤**:
1. 进入"设置"标签
2. 点击"积分中心"

**预期结果**:
1. 积分中心页面正确加载
2. 当前积分余额正确显示
3. 积分卡片样式正确渲染

### TC-4.2: 积分消费记录

**优先级**: 中  
**测试类型**: 单元测试

**测试步骤**:
1. 进入"积分中心"
2. 点击"查看详情"查看积分历史

**预期结果**:
1. 积分历史页面正确加载
2. 显示积分记录列表
3. 每条记录包含正确的金额、原因和日期

### TC-4.3: 积分充值界面

**优先级**: 高  
**测试类型**: 混合（单元测试+UI测试）

**测试步骤**:
1. 进入"积分中心"
2. 点击"充值积分"按钮
3. 等待充值页面加载
4. 选择一个充值套餐

**预期结果**:
1. 充值页面正确加载
2. 显示所有可用的充值套餐
3. 套餐金额和积分数量正确显示
4. 选择套餐后高亮显示

## 5. 网络监测测试

### TC-5.1: 网络状态检测

**优先级**: 高  
**测试类型**: 单元测试

**测试步骤**:
1. 初始化NetworkMonitor实例
2. 模拟网络连接状态变化
3. 观察isConnected属性和connectionType属性

**预期结果**:
1. NetworkMonitor正确检测网络状态变化
2. isConnected属性反映当前网络状态
3. connectionType属性反映正确的连接类型

### TC-5.2: 内购功能网络依赖

**优先级**: 高  
**测试类型**: 单元测试

**测试步骤**:
1. 模拟网络断开状态
2. 尝试在IAPManager中调用fetchProducts方法
3. 尝试在IAPManager中调用purchase方法

**预期结果**:
1. fetchProducts方法检测到网络断开并返回错误
2. purchase方法检测到网络断开并返回错误
3. 错误信息包含网络断开相关提示

### TC-5.3: 网络状态UI反馈

**优先级**: 中  
**测试类型**: UI测试

**测试步骤**:
1. 进入"积分中心"
2. 点击"充值积分"按钮
3. 模拟网络断开
4. 观察UI变化

**预期结果**:
1. 显示网络断开提示
2. 充值按钮变为禁用状态
3. 按钮颜色变灰
4. 网络恢复后UI自动更新

## 6. 测试工具类测试

### TC-6.1: TestDataGenerator测试

**优先级**: 中  
**测试类型**: 单元测试

**测试步骤**:
1. 测试标题生成
   ```swift
   func test_generateTitle_validLength() {
       let title = TestDataGenerator.generateTitle(length: 10)
       XCTAssertEqual(title.count, 10)
   }
   ```

2. 测试内容生成
   ```swift
   func test_generateContent_validLength() {
       let content = TestDataGenerator.generateContent(length: 50)
       XCTAssertEqual(content.count, 50)
   }
   ```

3. 测试积分生成
   ```swift
   func test_generatePoints_inRange() {
       let points = TestDataGenerator.generatePoints(in: 100...200)
       XCTAssertTrue((100...200).contains(points))
   }
   ```

4. 测试时间戳生成
   ```swift
   func test_generateTimestamp_validRange() {
       let date = TestDataGenerator.generateTimestamp(daysRange: -7...7)
       let now = Date()
       XCTAssertTrue(abs(date.timeIntervalSince(now)) <= 7 * 24 * 60 * 60)
   }
   ```

**预期结果**:
1. 生成的标题长度符合要求
2. 生成的内容长度符合要求
3. 生成的积分在指定范围内
4. 生成的时间戳在指定范围内

### TC-6.2: MockServices测试

**优先级**: 中  
**测试类型**: 单元测试

**测试步骤**:
1. 测试网络服务Mock
   ```swift
   func test_mockNetworkService_request() {
       let service = MockNetworkService()
       let testData = "test".data(using: .utf8)!
       
       service.mockResponse(for: "test_endpoint", data: testData)
       let result = service.request("test_endpoint")
       
       XCTAssertEqual(try? result?.get(), testData)
       XCTAssertTrue(service.verifyCall("request_test_endpoint"))
   }
   ```

2. 测试存储服务Mock
   ```swift
   func test_mockStorageService_storeAndRetrieve() {
       let service = MockStorageService()
       let testValue = "test_value"
       
       service.store(testValue, for: "test_key")
       let retrieved = service.retrieve("test_key") as? String
       
       XCTAssertEqual(retrieved, testValue)
       XCTAssertTrue(service.verifyCall("store_test_key"))
       XCTAssertTrue(service.verifyCall("retrieve_test_key"))
   }
   ```

3. 测试音频服务Mock
   ```swift
   func test_mockAudioService_playAndPause() {
       let service = MockAudioService()
       let testData = Data([1, 2, 3])
       
       service.play(testData)
       XCTAssertTrue(service.isPlaying)
       XCTAssertEqual(service.currentAudio, testData)
       
       service.pause()
       XCTAssertFalse(service.isPlaying)
   }
   ```

**预期结果**:
1. Mock网络服务正确处理请求和响应
2. Mock存储服务正确存储和检索数据
3. Mock音频服务正确模拟播放状态
4. 所有服务正确记录方法调用

### TC-6.3: AsyncTestHelper测试

**优先级**: 中  
**测试类型**: 单元测试

**测试步骤**:
1. 测试单个异步操作等待
   ```swift
   func test_wait_singleOperation() {
       AsyncTestHelper.wait(description: "Test wait") { expectation in
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
               expectation.fulfill()
           }
       }
   }
   ```

2. 测试多个异步操作等待
   ```swift
   func test_waitAll_multipleOperations() {
       AsyncTestHelper.waitAll(
           descriptions: ["Op1", "Op2"],
           operations: [
               { exp in exp.fulfill() },
               { exp in exp.fulfill() }
           ]
       )
   }
   ```

3. 测试条件等待
   ```swift
   func test_waitUntil_condition() {
       var flag = false
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           flag = true
       }
       
       let result = AsyncTestHelper.waitUntil { flag }
       XCTAssertTrue(result)
   }
   ```

4. 测试成功期望
   ```swift
   func test_expectSuccess() {
       AsyncTestHelper.expectSuccess { completion in
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
               completion(.success("test"))
           }
       }
   }
   ```

**预期结果**:
1. 单个异步操作等待成功
2. 多个异步操作等待成功
3. 条件等待正确工作
4. 成功期望正确验证

### 测试用例维护

- 每次修改工具类时更新相应的测试用例
- 定期检查测试覆盖率
- 确保测试用例与工具类功能同步更新

## 附录：测试用例维护

### 测试数据要求

- 测试前确保有至少3条内容数据
- 测试账户初始积分设置为100

### 测试环境设置

```swift
// 设置测试标记
app.launchArguments.append("--UITesting")

// 设置测试数据
app.launchEnvironment["TEST_USER_POINTS"] = "100"
app.launchEnvironment["DISABLE_ANIMATIONS"] = "YES"
```

### 测试覆盖范围

当前测试用例覆盖了忆刻应用的以下核心功能：

- 导航和基础UI (TC-1.1, TC-1.2)
- 内容管理 (TC-2.1, TC-2.2)
- 播放功能 (TC-3.1, TC-3.2, TC-3.3)
- 积分系统 (TC-4.1, TC-4.2, TC-4.3)
- 网络监测 (TC-5.1, TC-5.2, TC-5.3)
- 测试工具类 (TC-6.1, TC-6.2, TC-6.3)

### 测试维护计划

- 每次添加新功能时，相应增加测试用例
- 每月检查测试用例是否需要更新
- 根据功能使用频率调整测试优先级 