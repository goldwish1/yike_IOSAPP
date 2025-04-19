# 忆趣 (Yike) GitHub Actions 自动化工作流

本目录包含了忆趣应用的自动化CI/CD工作流配置，用于保证代码质量和应用稳定性。

## 工作流概述

### 1. 单元测试 (unit-tests.yml)

- **触发条件**：推送到 main/develop 分支或对这些分支发起PR
- **功能**：执行应用的所有单元测试
- **输出**：测试结果报告 (TestResults.xcresult)

### 2. UI测试 (ui-tests.yml)

- **触发条件**：
  - 手动触发 (workflow_dispatch)
  - 视图文件更改推送到 main 分支
- **功能**：执行应用的所有UI测试
- **输出**：UI测试结果报告 (TestResults.xcresult)

### 3. 构建测试 (build-test.yml)

- **触发条件**：推送到 main/develop/feature/bugfix 分支或对main/develop发起PR
- **功能**：验证项目是否能够正常构建
- **输出**：失败时提供构建日志

### 4. 代码覆盖率报告 (code-coverage.yml)

- **触发条件**：
  - 推送到 main 分支
  - 每周一自动运行
- **功能**：生成代码覆盖率报告
- **输出**：
  - HTML覆盖率报告
  - 在PR中添加覆盖率摘要评论

## 如何使用

### 手动触发UI测试

1. 在GitHub仓库页面导航到"Actions"选项卡
2. 在左侧选择"UI Tests"工作流
3. 点击"Run workflow"按钮
4. 选择要运行测试的分支
5. 点击"Run workflow"开始测试

### 查看测试结果

1. 在GitHub仓库页面导航到"Actions"选项卡
2. 选择相应的工作流运行记录
3. 在"Artifacts"部分可以下载测试结果或覆盖率报告

### 本地查看覆盖率报告

```bash
# 下载并解压覆盖率报告
cd ~/Downloads
unzip coverage-report.zip
open index.html
```

## 配置自定义

如需修改工作流配置，可编辑 `.github/workflows/` 目录下的相应YAML文件。

常见自定义选项：

- **Xcode版本**：修改 `xcode-version` 参数
- **测试目标设备**：修改 `-destination` 参数
- **触发条件**：调整 `on` 部分的分支或事件

## 故障排除

常见问题：

1. **构建失败**：检查是否有依赖项缺失或配置错误
2. **测试超时**：检查是否有UI测试卡住或运行时间过长
3. **Xcode版本问题**：确保工作流中指定的Xcode版本与项目兼容

如需帮助，请在仓库中创建Issue。 