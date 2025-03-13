# 忆刻项目目录结构

```
Yike/
├── Yike.xcodeproj/
├── .git/
├── test_results.json
├── YikeTests/
├── YikeUITests/
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
│   │   │   │   └── OCRService.swift            # OCR文字识别服务
│   │   │   └── Storage/      # 数据存储
│   │   │       ├── DataManager.swift           # 数据管理器
│   │   │       ├── Models.swift                # 数据模型
│   │   │       └── SettingsManager.swift       # 设置管理器
│   │   └── Features/         # 功能模块
│   │       ├── Settings/     # 设置功能
│   │       ├── Input/        # 输入功能
│   │       ├── Player/       # 播放功能
│   │       ├── Points/       # 积分功能
│   │       ├── Study/        # 学习功能
│   │       └── Home/         # 首页功能
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
5. `Yike/`: 主项目目录
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
         - `OCRService.swift`: OCR文字识别服务，处理图片文字识别
       - `Storage/`: 数据存储层
         - `DataManager.swift`: 数据管理器，处理核心数据的CRUD操作
         - `Models.swift`: 数据模型定义，包含所有核心数据结构
         - `SettingsManager.swift`: 设置管理器，处理应用配置的存储和读取
     - `Features/`: 功能模块
       - `Settings/`: 设置相关功能
       - `Input/`: 内容输入功能（OCR、手动输入等）
       - `Player/`: 播放功能（语音播放、控制等）
       - `Points/`: 积分系统功能
       - `Study/`: 学习相关功能
       - `Home/`: 首页功能
   - `.cursorrules`: Cursor IDE 配置文件
   - `Yike.xcdatamodeld/`: Core Data 模型文件
   - `Persistence.swift`: 数据持久化管理
   - `Preview Content/`: SwiftUI 预览资源
   - `Assets.xcassets/`: 项目资源文件
6. `Yike.xctestplan`: 测试计划文件
7. `TestResults.xcresult/`: Xcode 测试结果
8. `TestResults/`: 测试结果目录 