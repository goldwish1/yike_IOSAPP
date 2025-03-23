# 忆刻应用UI冒烟测试指南

本文档提供忆刻应用UI冒烟测试的设置和执行说明。UI冒烟测试专注于通过用户界面验证核心功能是否正常工作。

## 测试范围

UI冒烟测试覆盖以下核心功能：
- 应用启动和主页加载
- 标签页导航
- 内容创建
- 播放功能基本流程

详细测试用例可在 `TestCases.md` 中查看。

## 测试架构

UI测试基于XCTest框架和XCUITest，使用以下架构：
- 测试类在 `YikeUITests/UISmokeTesting` 目录下
- 使用专用的 `YikeSmokeUITest.xctestplan` 测试计划配置

## 运行测试

### 方法1：使用Xcode

1. 打开Xcode项目
2. 在测试导航器中选择 `YikeSmokeUITest` 测试计划
3. 点击运行按钮执行测试

### 方法2：使用命令行

可以使用提供的 `run_ui_smoke_tests.sh` 脚本：

```bash
cd /Users/fengyuanzhou/Desktop/IOS\ APP/Yike/Yike
./scripts/run_ui_smoke_tests.sh
```

可选参数：
- `--report`: 生成HTML测试报告
- `--verbose`: 显示详细输出

示例：
```bash
./scripts/run_ui_smoke_tests.sh --report --verbose
```

## 注意事项

1. 确保模拟器设置正确，脚本将自动选择可用的iPhone模拟器
2. 测试数据将自动生成，无需手动创建测试数据
3. UI测试可能稍慢，请耐心等待

## 故障排除

**问题：找不到UI元素**

可能的解决方案：
- 确保元素有正确的无障碍标签(Accessibility Label)
- 增加等待超时时间
- 检查应用UI是否有变更

**问题：测试间歇性失败**

可能的解决方案：
- 增加等待时间和超时时间
- 关闭模拟器上的其他应用
- 重启模拟器

## 维护测试

每次UI发生变化或添加新功能时，应该更新测试：

1. 更新UI元素标识符和测试断言
2. 添加新的测试用例覆盖新功能
3. 定期检查现有测试有效性 