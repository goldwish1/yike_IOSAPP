## SpecStory

## Yike iOS App Documentation and Planning (2025/3/11 03:48:39)

_**User**_

@Yike iOS App Project Documentation and Planning 

---

_**Assistant**_

收到大帅哥

我来帮你查看一下Yike iOS应用的项目文档和规划情况。首先，让我浏览一下项目的结构，了解当前的开发状态。

---

_****_

<details>
            <summary>Listed current directory • **12** results</summary>
        
| Name |
|-------|
| 📄 `devstatus.md` |
| 📄 `Info.plist` |
| 📁 `Yike` |
| 📄 `README.md` |
| 📄 `.DS_Store` |
| 📄 `.cursorrules` |
| 📁 `.specstory` |
| 📁 `Yike.xcdatamodeld` |
| 📄 `Persistence.swift` |
| 📁 `Preview Content` |
| 📁 `Assets.xcassets` |
| 📁 `原型设计` |

</details>

---

_****_

让我先查看README.md文件，了解项目的基本情况和目标：

---

_****_

Read file: undefined

---

_****_

接下来，让我查看开发状态文档，了解当前的开发进度：

---

_****_

Read file: undefined

---

_****_

现在，让我查看一下项目的核心结构，特别是数据管理部分：

---

_****_

<details>
            <summary>Listed directory Yike/Core • **4** results</summary>
        
| Name |
|-------|
| 📁 `Services` |
| 📁 `Utils` |
| 📁 `Storage` |
| 📁 `Network` |

</details>

---

_****_

让我查看一下数据管理相关的文件：

---

_****_

<details>
            <summary>Listed directory Yike/Core/Storage • **3** results</summary>
        
| Name |
|-------|
| 📄 `Models.swift` |
| 📄 `DataManager.swift` |
| 📄 `SettingsManager.swift` |

</details>

---

_****_

让我查看一下数据模型和数据管理器的实现：

---

_****_

Read file: undefined

---

_****_

Read file: undefined

---

_****_

Read file: undefined

---

_****_

让我查看一下主要功能模块的实现：

---

_****_

<details>
            <summary>Listed directory Yike/Features • **6** results</summary>
        
| Name |
|-------|
| 📁 `Input` |
| 📁 `Settings` |
| 📁 `Points` |
| 📁 `Study` |
| 📁 `Player` |
| 📁 `Home` |

</details>

---

_****_

让我查看一下主页视图的实现：

---

_****_

Read file: undefined

---

_****_

让我查看一下输入模块的实现：

---

_****_

<details>
            <summary>Listed directory Yike/Features/Input • **4** results</summary>
        
| Name |
|-------|
| 📄 `InputSelectionView.swift` |
| 📄 `CameraOptionsView.swift` |
| 📄 `ImagePicker.swift` |
| 📄 `PreviewEditView.swift` |

</details>

---

_****_

Read file: undefined

---

_****_

让我查看一下播放器模块的实现：

---

_****_

<details>
            <summary>Listed directory Yike/Features/Player • **1** results</summary>
        
| Name |
|-------|
| 📄 `PlayerView.swift` |

</details>

---

_****_

现在，让我查看一下设置模块的实现：

---

_****_

<details>
            <summary>Listed directory Yike/Features/Settings • **5** results</summary>
        
| Name |
|-------|
| 📄 `PlaySettingsView.swift` |
| 📄 `AboutView.swift` |
| 📁 `Documents` |
| 📄 `ReminderSettingsView.swift` |
| 📄 `SettingsView.swift` |

</details>

---

_****_

Read file: undefined

---

_****_

基于我对项目的分析，我可以为你提供一个全面的项目文档和规划总结：

# 忆刻（Yike）iOS应用项目总结

## 项目概述

忆刻是一款基于科学记忆方法的智能背诵辅助工具，专为学生设计，通过听觉重复和智能提醒来提升记忆效率。应用采用SwiftUI框架开发，目前已完成MVP版本的主要功能开发。

## 当前开发状态

### 已完成功能

1. **内容输入模块**
   - OCR文本识别（相机/相册）
   - 手动文本输入
   - 自动提取标题功能
   - 内容预览编辑
   - 内容删除功能

2. **播放控制模块**
   - 文本转语音（AVSpeechSynthesizer）
   - 播放控制（播放/暂停、上一句/下一句）
   - 速度调节（0.5x-2.0x）
   - 自动循环播放
   - 三种预设音色（标准、轻柔、浑厚）
   - 语音试听功能

3. **艾宾浩斯记忆系统**
   - 基于艾宾浩斯遗忘曲线的记忆提醒
   - 三种复习策略（简单/标准/密集）
   - 学习进度追踪

4. **统计与数据**
   - 学习统计（完成项目、进度）
   - 本地数据存储（UserDefaults）

5. **积分系统**
   - 积分明细记录
   - 积分消费逻辑

6. **设置中心**
   - 播放设置（音色、速度、间隔）
   - 提醒设置（每日提醒、复习策略）
   - 关于页面

### 最新进展

- **2024-03-10**: 优化了播放设置界面，简化了音色选择，提供三种预设音色
- **2024-03-09**: 添加了语音试听功能，优化了音色差异
- **2024-03-08**: 实现了OCR拍照输入功能，支持中英文多语言识别
- **2024-03-07**: 优化了内容输入流程，新增自动提取标题功能

### 待开发功能（下一版本计划）

1. **用户系统**
   - 账号注册登录
   - 数据云同步

2. **社交功能**
   - 内容分享
   - 学习小组

3. **AI 助手**
   - 智能分析
   - 学习建议

## 技术架构

- **UI框架**: SwiftUI
- **数据存储**: UserDefaults（计划迁移到Core Data）
- **语音合成**: AVFoundation (AVSpeechSynthesizer)
- **文字识别**: Vision框架

## 代码结构

项目采用模块化结构，主要分为以下几个部分：

1. **Core**: 核心功能模块
   - Storage: 数据存储和管理
   - Services: 服务层
   - Utils: 工具类
   - Network: 网络请求

2. **Features**: 功能模块
   - Home: 主页视图
   - Input: 内容输入
   - Player: 播放控制
   - Study: 学习管理
   - Points: 积分系统
   - Settings: 设置中心

## 数据模型

1. **MemoryItem**: 记忆项目模型
   - 包含标题、内容、进度、复习阶段等信息
   - 支持艾宾浩斯记忆曲线的复习计划

2. **PointsRecord**: 积分记录模型
   - 记录积分收支情况

3. **UserSettings**: 用户设置模型
   - 播放设置（音色、速度、间隔）
   - 提醒设置（时间、方式、策略）

## 优化建议

1. **数据存储优化**
   - 从UserDefaults迁移到Core Data，提高数据管理效率
   - 实现数据备份和恢复功能

2. **用户体验改进**
   - 优化播放器界面，增加更丰富的视觉反馈
   - 完善OCR识别功能，提高识别准确率

3. **性能优化**
   - 优化语音合成过程，减少播放延迟
   - 改进内存管理，避免可能的内存泄漏

4. **功能扩展**
   - 实现用户系统和云同步
   - 添加社交分享功能
   - 集成AI助手，提供智能学习建议

## 总结

忆刻应用目前已经完成了MVP版本的主要功能开发，包括内容输入、播放控制、记忆系统和设置管理等核心功能。应用采用现代化的SwiftUI框架开发，具有良好的用户界面和交互体验。下一步将重点开发用户系统和云同步功能，以及增强社交和AI功能，进一步提升应用的价值和用户体验。

---

_**User**_

现在我们打算集成专业的第三方语音合成服务，如豆包API、讯飞语音、百度语音等，这些服务通常提供更多样化的音色选择，请帮我确认下实现步骤。另外，我们这个功能应该是付费功能，用户可以试听，但如果正式选择，需要消耗积分

---

_**Assistant**_



---



---

