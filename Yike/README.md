# 忆刻 (Yike) - 智能记忆辅助应用

忆刻是一款基于科学记忆方法的智能背诵辅助工具，专注于帮助学生通过听觉重复和智能提醒来提升记忆效率。

## 产品亮点

- 📝 智能文本识别：支持拍照OCR和手动输入
- �� 智能语音播放：自定义语音、速度和间隔，支持自动循环播放
- ⏰ 科学记忆提醒：基于艾宾浩斯遗忘曲线
- 📊 学习数据分析：直观展示学习进度
- 🌟 积分激励系统：合理定价，学生友好

## 技术架构

- 开发环境：Xcode 15+
- 系统要求：iOS 13.0+
- 框架选择：
  - SwiftUI：现代化UI构建
  - Core Data：本地数据存储
  - Vision：OCR文字识别
  - AVFoundation：语音合成

## 项目结构

```
Yike/
├── App/
│   ├── YikeApp.swift
│   └── ContentView.swift
├── Core/
│   └── Storage/
│       ├── DataManager.swift
│       ├── Models.swift
│       └── SettingsManager.swift
└── Features/
    ├── Home/
    │   └── HomeView.swift
    ├── Input/
    │   ├── InputSelectionView.swift
    │   └── PreviewEditView.swift
    ├── Player/
    │   └── PlayerView.swift
    ├── Study/
    │   └── StudyView.swift
    ├── Points/
    │   ├── PointsCenterView.swift
    │   └── PointsHistoryView.swift
    └── Settings/
        ├── SettingsView.swift
        ├── PlaySettingsView.swift
        ├── ReminderSettingsView.swift
        └── AboutView.swift
```

## 最新更新

1. 优化了内容输入流程
   - 新增自动提取标题功能
   - 优化了保存后的导航逻辑

2. 改进了播放功能
   - 新增自动循环播放
   - 优化了播放控制逻辑

## 安装说明

1. 克隆项目
```bash
git clone https://github.com/yourusername/Yike.git
```

2. 安装依赖
```bash
cd Yike
pod install
```

3. 打开项目
```bash
open Yike.xcworkspace
```

## 文档

- [产品需求文档](./原型设计/PRD.md)
- [API文档](./豆包API调用)
- [开发计划](./devstatus.md)

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 许可证

[MIT](LICENSE) 