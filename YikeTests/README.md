# 忆刻应用冒烟测试指南

本文档提供了关于如何设置和运行忆刻应用冒烟测试的详细说明。冒烟测试旨在验证应用的核心功能在代码变更后仍能正常工作。

## 测试范围

当前冒烟测试套件覆盖以下核心功能：

- 基础导航和UI
- 内容创建与管理
- 播放功能
- 积分系统
- 网络监测

详细的测试用例请参考 [TestCases.md](./TestCases.md)。

## 准备工作

### 前提条件

- Xcode 13.0 或更高版本
- iOS 15.0 或更高版本的模拟器或设备
- 忆刻项目代码

### 设置测试环境

1. 打开 Yike.xcodeproj
2. 选择 "Product" > "Scheme" > "Edit Scheme..."
3. 在左侧选择 "Test"
4. 确保已选择 "YikeSmokeTest.xctestplan"
5. 点击 "Close"

## 运行冒烟测试

### 方法一：使用 Xcode UI

1. 在 Xcode 中，确保已选择正确的测试计划
2. 选择目标设备或模拟器
3. 按下 Command+U 或选择 "Product" > "Test" 运行所有测试

### 方法二：命令行运行

```bash
# 运行所有冒烟测试
xcodebuild test -project Yike.xcodeproj -scheme YikeTests -testPlan YikeSmokeTest -destination 'platform=iOS Simulator,name=iPhone 12,OS=15.0'

# 运行特定测试类
xcodebuild test -project Yike.xcodeproj -scheme YikeTests -testPlan YikeSmokeTest -destination 'platform=iOS Simulator,name=iPhone 12,OS=15.0' -only-testing:YikeTests/NetworkMonitorSmokeTests
```

### 方法三：使用快捷脚本

项目根目录提供了运行冒烟测试的快捷脚本：

```bash
# 运行所有冒烟测试
./scripts/run_smoke_tests.sh

# 运行并生成HTML报告
./scripts/run_smoke_tests.sh --report
```

## 运行UI冒烟测试

### 方法一：使用Xcode UI

1. 在Xcode中打开项目
2. 在"Product"菜单中选择"Test Plan"，选择"YikeSmokeUITest"
3. 点击"Product > Test"或使用快捷键⌘U运行测试

### 方法二：使用命令行

使用以下命令运行UI测试：

```bash
cd /path/to/Yike
xcodebuild test -project Yike.xcodeproj -scheme YikeTests -testPlan YikeSmokeUITest -destination 'platform=iOS Simulator,name=iPhone 15' | xcbeautify
```

### 方法三：使用便捷脚本

项目包含可执行脚本简化UI测试启动过程：

```bash
cd /path/to/Yike
./scripts/run_ui_smoke_tests.sh
```

## 测试结果解读

### 成功标准

冒烟测试成功的标准为：

1. 所有测试用例通过（绿色对勾）
2. 没有崩溃或异常
3. 测试执行时间在预期范围内

### 失败分析

如果测试失败：

1. 查看失败的测试用例和错误信息
2. 检查最近的代码变更是否影响了相关功能
3. 在本地重现并调试问题
4. 修复后重新运行测试

## 常见问题排查

### 测试超时

- 增加等待超时时间
- 检查应用性能是否有退化
- 确认测试设备资源充足

### UI元素找不到

- 检查元素ID是否已更改
- 确认页面层次结构是否变化
- 尝试使用更灵活的查找方式（如predicate）

### 网络测试失败

- 确保NetworkMonitor在测试环境中正确响应模拟状态
- 检查是否有防火墙或网络限制

### 内购测试失败

- 检查StoreKit配置文件是否正确
- 确认应用内购流程是否正常

### UI测试失败

- 检查UI测试中的bundleIdentifier是否正确
- 确认UI元素是否已更改

## 维护测试

### 何时更新测试

在以下情况需要更新冒烟测试：

1. 添加新功能
2. 修改现有功能的行为
3. 更改UI元素的标识符
4. 调整应用流程或导航

### 如何添加新测试

1. 确定需要测试的功能
2. 在 [TestCases.md](./TestCases.md) 中添加测试用例描述
3. 在适当的测试类中实现测试方法
4. 遵循命名约定：`test_[功能]_[条件]_[预期结果]()`

## 持续集成

冒烟测试已集成到CI流程中：

1. 每次提交代码后自动运行
2. 在创建合并请求时运行
3. 发布新版本前运行

CI结果可在项目仓库的Actions页面查看。

## 联系人

如对测试有任何问题，请联系项目负责人。 