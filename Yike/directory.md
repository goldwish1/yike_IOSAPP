# 忆刻项目目录结构

```
Yike/
├── Yike.xcodeproj/
├── .git/
├── test_results.json
├── YikeTests/
├── YikeUITests/
├── YikeUITests_record/                # UI测试录制目录
│   ├── YikeUITests_record.swift       # UI测试录制主文件
│   ├── YikeUITests_recordLaunchTests.swift # 启动测试文件
│   ├── info.plist                     # 配置文件
│   └── .DS_Store
├── Yike/
│   ├── devstatus.md
│   ├── en.lproj/
│   ├── zh-Hans.lproj/
│   ├── docs/
│   ├── PRD.md
│   ├── README.md
│   ├── Info.plist
│   ├── Yike/                   # 源代码目录
│   │   ├── App/               # 应用程序入口
│   │   │   ├── YikeApp.swift
│   │   │   └── ContentView.swift
│   │   ├── Core/             # 核心功能
│   │   │   ├── Services/     # 服务层
│   │   │   │   ├── AudioPlayerService.swift    # 音频播放服务
│   │   │   │   ├── SiliconFlowTTSService.swift # 硅基流动语音合成服务
│   │   │   │   ├── NavigationService.swift     # 导航服务
│   │   │   │   ├── NavigationRouter.swift      # 导航路由管理器
│   │   │   │   └── OCRService.swift            # OCR文字识别服务
│   │   │   └── Storage/      # 数据存储
│   │   │       ├── DataManager.swift           # 数据管理器
│   │   │       ├── Models.swift                # 数据模型
│   │   │       └── SettingsManager.swift       # 设置管理器
│   │   └── Features/         # 功能模块
│   │       ├── Settings/     # 设置功能
│   │       │   ├── SettingsView.swift          # 设置页面
│   │       │   ├── PlaySettingsView.swift      # 播放设置页面
│   │       │   ├── ReminderSettingsView.swift  # 提醒设置页面
│   │       │   ├── AboutView.swift             # 关于页面
│   │       │   └── Documents/                  # 文档页面
│   │       │       ├── UserAgreementView.swift # 用户协议页面
│   │       │       └── PrivacyPolicyView.swift # 隐私政策页面
│   │       ├── Input/        # 输入功能
│   │       │   ├── InputSelectionView.swift    # 输入选择页面
│   │       │   ├── CameraOptionsView.swift     # 相机选项页面
│   │       │   └── PreviewEditView.swift       # 预览编辑页面
│   │       ├── Player/       # 播放功能
│   │       │   ├── PlayerView.swift            # 播放页面主视图
│   │       │   ├── Services/                   # 播放相关服务
│   │       │   │   ├── SpeechManager.swift     # 语音管理器
│   │       │   │   ├── LocalVoicePlaybackManager.swift  # 本地语音播放管理器
│   │       │   │   └── ApiVoicePlaybackManager.swift    # API语音播放管理器
│   │       │   ├── ViewModels/                 # 视图模型
│   │       │   │   └── PlaybackControlViewModel.swift   # 播放控制视图模型
│   │       │   └── Views/                      # 子视图组件
│   │       │       ├── PlayerControlsView.swift         # 播放控制视图
│   │       │       ├── PlaybackProgressView.swift       # 播放进度视图
│   │       │       ├── WaveformAnimationView.swift      # 波形动画视图
│   │       │       └── SpeedSelectionView.swift         # 速度选择视图
│   │       ├── Points/       # 积分功能
│   │       │   ├── PointsCenterView.swift      # 积分中心页面
│   │       │   └── PointsHistoryView.swift     # 积分历史页面
│   │       ├── Study/        # 学习功能
│   │       │   └── StudyView.swift             # 学习页面
│   │       └── Home/         # 首页功能
│   │           └── HomeView.swift              # 首页
│   ├── .cursorrules
│   ├── Yike.xcdatamodeld/
│   ├── Persistence.swift
│   ├── Preview Content/
│   └── Assets.xcassets/
├── Yike.xctestplan
├── TestResults.xcresult/
└── TestResults/
```

## 文件说明

1. `Yike.xcodeproj/`: Xcode 项目文件
2. `test_results.json`: 测试结果数据
3. `YikeTests/`: 单元测试目录
4. `YikeUITests/`: UI测试目录
5. `YikeUITests_record/`: UI测试录制目录
   - `YikeUITests_record.swift`: UI测试录制主文件
   - `YikeUITests_recordLaunchTests.swift`: 启动测试文件
   - `info.plist`: 测试配置文件
6. `Yike/`: 主项目目录
   - `devstatus.md`: 开发状态文档
   - `en.lproj/`: 英文本地化资源
   - `zh-Hans.lproj/`: 简体中文本地化资源
   - `docs/`: 项目文档
   - `PRD.md`: 产品需求文档
   - `README.md`: 项目说明文档
   - `Info.plist`: 项目配置文件
   - `Yike/`: 源代码目录
     - `App/`: 应用程序入口
       - `YikeApp.swift`: 应用程序入口点
       - `ContentView.swift`: 主内容视图
     - `Core/`: 核心功能
       - `Services/`: 服务层
         - `AudioPlayerService.swift`: 音频播放服务，负责音频播放控制和管理
         - `SiliconFlowTTSService.swift`: 硅基流动语音合成服务，处理在线语音合成
         - `NavigationService.swift`: 导航服务，管理应用内页面导航和路由，支持iOS 16新特性
         - `NavigationRouter.swift`: 导航路由管理器，负责管理应用内导航状态和路由
         - `OCRService.swift`: OCR文字识别服务，处理图片文字识别
       - `Storage/`: 数据存储层
         - `DataManager.swift`: 数据管理器，处理核心数据的CRUD操作
         - `Models.swift`: 数据模型定义，包含所有核心数据结构
         - `SettingsManager.swift`: 设置管理器，处理应用配置的存储和读取
     - `Features/`: 功能模块
       - `Settings/`: 设置相关功能
         - `SettingsView.swift`: 设置页面，提供各种设置入口
         - `PlaySettingsView.swift`: 播放设置页面，配置播放相关参数
         - `ReminderSettingsView.swift`: 提醒设置页面，配置提醒相关参数
         - `AboutView.swift`: 关于页面，显示应用信息
         - `Documents/`: 文档页面
           - `UserAgreementView.swift`: 用户协议页面
           - `PrivacyPolicyView.swift`: 隐私政策页面
       - `Input/`: 内容输入功能（OCR、手动输入等）
         - `InputSelectionView.swift`: 输入选择页面，选择输入方式
         - `CameraOptionsView.swift`: 相机选项页面，提供拍照和相册选择
         - `PreviewEditView.swift`: 预览编辑页面，编辑识别或输入的内容
       - `Player/`: 播放功能（语音播放、控制等）
         - `PlayerView.swift`: 播放页面主视图，整合各个子组件
         - `Services/`: 播放相关服务
           - `SpeechManager.swift`: 语音管理器，处理文本转语音核心功能
           - `LocalVoicePlaybackManager.swift`: 本地语音播放管理器，处理系统语音合成
           - `ApiVoicePlaybackManager.swift`: API语音播放管理器，处理在线语音合成
         - `ViewModels/`: 视图模型
           - `PlaybackControlViewModel.swift`: 播放控制视图模型，处理播放状态和业务逻辑
         - `Views/`: 子视图组件
           - `PlayerControlsView.swift`: 播放控制视图，包含播放/暂停、上一条/下一条按钮
           - `PlaybackProgressView.swift`: 播放进度视图，显示播放进度和时间
           - `WaveformAnimationView.swift`: 波形动画视图，显示播放状态的动画效果
           - `SpeedSelectionView.swift`: 速度选择视图，提供播放速度调节功能
       - `Points/`: 积分系统功能
         - `PointsCenterView.swift`: 积分中心页面，显示积分余额和充值入口
         - `PointsHistoryView.swift`: 积分历史页面，显示积分消费记录
       - `Study/`: 学习相关功能
         - `StudyView.swift`: 学习页面，显示学习进度和统计
       - `Home/`: 首页功能
         - `HomeView.swift`: 首页，显示内容列表和新建入口
   - `.cursorrules`: Cursor IDE 配置文件
   - `Yike.xcdatamodeld/`: Core Data 模型文件
   - `Persistence.swift`: 数据持久化管理
   - `Preview Content/`: SwiftUI 预览资源
   - `Assets.xcassets/`: 项目资源文件
7. `Yike.xctestplan`: 测试计划文件
8. `TestResults.xcresult/`: Xcode 测试结果
9. `TestResults/`: 测试结果目录 