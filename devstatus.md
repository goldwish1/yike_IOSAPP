# 忆刻开发计划

## 单元测试实施计划

### 1. 测试架构分析
- [x] 分析项目结构和核心功能
- [x] 确定测试范围和优先级
- [x] 设计测试架构和目录结构
- [x] 制定测试实施步骤

### 2. 测试基础设施
- [x] 创建测试目录结构
- [x] 实现 YikeBaseTests 基础测试类
- [x] 实现 TestHelpers 测试辅助工具类
- [x] 实现 TestDataProvider 测试数据提供者
- [x] 编写测试指南文档

### 3. 核心模拟对象
- [x] 创建MockUserDefaults
  - [x] 实现UserDefaults所有关键方法
  - [x] 添加状态验证功能
  - [x] 实现值记录和验证机制
- [x] 创建MockFileManager
  - [x] 模拟文件系统操作
  - [x] 实现文件存在性检查
  - [x] 添加文件操作错误模拟
- [x] 创建MockURLSession
  - [x] 模拟网络请求和响应
  - [x] 实现请求验证功能
  - [x] 添加错误和超时模拟
- [x] 创建MockAVAudioPlayer
  - [x] 模拟音频播放功能
  - [x] 实现播放状态管理
  - [x] 添加播放事件回调
- [x] 创建MockAVSpeechSynthesizer
  - [x] 模拟语音合成功能
  - [x] 实现合成状态管理
  - [x] 添加合成事件回调
- [ ] 创建MockVisionFramework

### 4. 服务层测试
- [ ] 测试 AudioPlayerService
- [ ] 测试 SiliconFlowTTSService
- [ ] 测试 NavigationService
- [ ] 测试 OCRService

### 5. 数据层测试
- [ ] 测试 DataManager
- [ ] 测试 SettingsManager
- [ ] 测试 Models

### 6. 视图模型测试
- [ ] 测试 PlaybackControlViewModel
- [ ] 测试 PointsViewModel
- [ ] 测试 StudyViewModel

### 7. 播放功能测试
- [ ] 测试 LocalVoicePlaybackManager
- [ ] 测试 ApiVoicePlaybackManager
- [ ] 测试 SpeechManager

### 8. 集成测试
- [ ] 测试组件间交互
- [ ] 测试数据流
- [ ] 测试用户场景

### 9. 性能测试
- [ ] 测试启动时间
- [ ] 测试内存使用
- [ ] 测试播放性能

## MVP版本功能 (v1.0.0)

### 1. 内容输入模块
- [x] OCR文本识别
  - 相机调用与图片获取
  - Vision框架集成
  - 识别结果处理
- [x] 手动文本输入
  - 输入界面设计
  - 字数限制(250字)
  - 分段预览功能
- [x] 自动提取标题
- [x] 内容预览编辑
- [x] 内容删除功能
  - 长按/右滑触发删除选项
  - 删除确认弹窗
  - 数据清理逻辑 