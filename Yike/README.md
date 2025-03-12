# 忆刻 (Yike) - 智能记忆辅助应用

忆刻是一款基于科学记忆方法的智能背诵辅助工具，专注于帮助学生通过听觉重复和智能提醒来提升记忆效率。

## 产品亮点

- 📝 智能文本识别：支持拍照OCR和手动输入
- 🎤 智能语音播放：自定义语音、速度和间隔，支持自动循环播放
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

1. **完成积分消耗功能测试**
   - 实现了单元测试、集成测试和UI测试
   - 验证了在线语音功能消耗5积分/次
   - 验证了OCR识别功能和试听功能免费
   - 优化了UI元素，添加了测试标识符
   - 使用方法交换技术解决单例测试问题
   - 修复了测试中的警告和错误，确保所有测试通过

2. **优化播放页面导航功能**
   - 实现在播放页面直接切换不同记忆内容
   - 优化上一条/下一条按钮的逻辑
   - 改进播放状态的管理
   - 优化编辑按钮UI设计
   - 提升整体用户操作体验

3. **添加内容编辑功能**
   - 在播放页面添加编辑按钮
   - 支持修改已保存内容的标题和正文
   - 优化编辑后的数据处理逻辑
   - 自动清理编辑后的语音缓存

4. **完成硅基流动API语音合成服务集成**
   - 实现高质量在线语音合成功能
   - 支持多种音色选择与试听
   - 建立音频缓存系统，优化重复请求

5. **调整在线语音功能积分消耗**
   - 将在线语音积分消耗从1积分调整为5积分
   - 优化了积分不足时的提示信息

6. **优化了内容输入流程**
   - 新增自动提取标题功能
   - 优化了保存后的导航逻辑

7. **改进了播放功能**
   - 新增自动循环播放
   - 优化了播放控制逻辑

8. **增加了内容管理功能**
   - 新增内容删除功能（长按/右滑触发）
   - 添加删除确认机制

9. **修复了设置页面问题**
   - 实现了用户协议、隐私政策和联系我们的跳转功能

## 安装说明

1. 克隆项目
```bash
git clone https://github.com/yourusername/Yike.git
```