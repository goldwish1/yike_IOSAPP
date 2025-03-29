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
- 系统要求：iOS 16.0+
- 框架选择：
  - SwiftUI：现代化UI构建
  - Core Data：本地数据存储
  - Vision：OCR文字识别
  - AVFoundation：语音合成
  - Network：网络状态监控
  - StoreKit 2：内购功能实现
  - NavigationStack：现代化导航管理
- 设计模式：
  - MVVM：视图与业务逻辑分离
  - 单例模式：全局服务管理
  - 依赖注入：提高代码可测试性
  - 发布-订阅模式：使用Combine框架实现状态管理
  - 观察者模式：网络状态监控与UI更新

## 项目结构

- 参考 @directory文件

## 最新更新

0. **添加技术支持网站功能**
   - 创建专用技术支持网页(support.html)
   - 在关于页面添加技术支持链接
   - 为App Store审核准备技术支持URL
   - 编写技术支持网站部署和维护说明文档
   - 添加App Store Connect提交指南

1. **优化应用导航体系与UI布局**
   - 统一页面呈现方式，将sheet形式改为导航形式
   - 优化AboutView、UserAgreementView和PrivacyPolicyView导航方式
   - 将积分充值页面从sheet模式改为常规导航
   - 解决页面底部内容与TabBar重叠问题
   - 移除多余的NavigationView和关闭按钮
   - 统一整个应用的导航体验
   - 为NavigationRouter添加新的路由支持
   - 提升整体用户界面一致性和体验

2. **升级应用最低系统要求至iOS 16**
   - 提高系统要求从iOS 13.0+升级到iOS 16.0+
   - 优化导航架构，移除混合导航代码
   - 全面使用NavigationStack实现现代化导航
   - 解决导航不一致性问题
   - 提升应用整体性能和稳定性

3. **修复内购功能网络依赖问题**
   - 创建NetworkMonitor服务类监控网络连接状态
   - 增强IAPManager的网络检查功能
   - 优化PointsRechargeView界面，添加网络状态提示
   - 在无网络情况下自动禁用购买按钮
   - 确保内购交易有网络验证，防止假交易
   - 全面测试各种网络状况下的表现
   - 提供清晰的网络错误提示和恢复机制
   - 符合Apple内购最佳实践

4. **修复在线语音播放完成确认按钮问题**
   - 解决播放设置页面退出时需要多次点击确认按钮的问题
   - 优化资源释放机制，确保播放资源完全释放
   - 改进播放停止逻辑和执行顺序
   - 添加必要的延迟确保异步操作完成
   - 统一本地语音和在线语音的行为模式

5. **添加在线语音功能Beta标识**
   - 在设置页面和播放页面添加Beta标识
   - 明确在线语音功能的迭代状态
   - 降低用户对功能稳定性的期望
   - 保持统一的视觉设计风格

5. **优化播放控制功能**
   - 统一本地语音和在线语音模式下的按钮行为
   - 实现切换记忆项目后自动播放功能
   - 优化按钮状态逻辑，提供一致的用户体验
   - 改进异步操作处理，避免播放冲突

6. **积分不足提示优化与跳转功能实现**
   - 优化积分不足错误提示文本
   - 实现点击提示直接跳转到积分中心
   - 添加NavigationRouter环境对象注入
   - 提升用户充值体验

7. **实现通知功能**
   - 创建NotificationManager服务类
   - 实现艾宾浩斯记忆曲线提醒功能
   - 支持多种提醒方式（仅通知、通知+声音、通知+震动）
   - 添加通知权限请求和状态检查

8. **苹果内购(IAP)功能分析与规划**
   - 完成现状分析和实现计划
   - 设计IAPManager服务类结构
   - 规划UI更新和测试策略
   - 更新开发状态文档

9. **完成单元测试全面实施**
   - 实现了全面的核心服务层测试
   - 完善了数据层测试
   - 增强了视图模型测试
   - 改进了音频处理测试
   - 优化了测试基础设施
   - 所有测试用例均已通过
   - 达成预定测试覆盖率目标

10. **PlayerView功能拆分和重构**
    - 将SpeechManager移至独立文件
    - 创建了LocalVoicePlaybackManager和ApiVoicePlaybackManager
    - 创建了PlaybackControlViewModel处理播放控制逻辑
    - 拆分UI组件为多个独立视图
    - 采用MVVM架构重构PlayerView

11. **完成导航系统升级**
    - 创建了NavigationService和NavigationRouter服务类
    - 支持iOS 16新特性，同时保持向下兼容
    - 将NavigationView升级为NavigationStack
    - 使用新的navigationDestination API替换旧的NavigationLink

12. **升级应用导航系统**
    - 创建了NavigationService服务类，集中管理应用导航逻辑
    - 支持iOS 16新特性，同时保持向下兼容
    - 优化页面间导航体验，减少代码重复
    - 解决了NavigationLink废弃警告问题
    - 提高了代码可维护性和扩展性

13. **完成积分消耗功能测试**
    - 实现了单元测试、集成测试和UI测试
    - 验证了在线语音功能消耗5积分/次
    - 验证了OCR识别功能和试听功能免费
    - 优化了UI元素，添加了测试标识符
    - 使用方法交换技术解决单例测试问题
    - 修复了测试中的警告和错误，确保所有测试通过

14. **优化播放页面导航功能**
    - 实现在播放页面直接切换不同记忆内容
    - 优化上一条/下一条按钮的逻辑
    - 改进播放状态的管理
    - 优化编辑按钮UI设计
    - 提升整体用户操作体验

15. **添加内容编辑功能**
    - 在播放页面添加编辑按钮
    - 支持修改已保存内容的标题和正文
    - 优化编辑后的数据处理逻辑
    - 自动清理编辑后的语音缓存

16. **完成硅基流动API语音合成服务集成**
    - 实现高质量在线语音合成功能
    - 支持多种音色选择与试听
    - 建立音频缓存系统，优化重复请求

17. **调整在线语音功能积分消耗**
    - 将在线语音积分消耗从1积分调整为5积分
    - 优化了积分不足时的提示信息

18. **优化了内容输入流程**
    - 新增自动提取标题功能
    - 优化了保存后的导航逻辑

19. **改进了播放功能**
    - 新增自动循环播放
    - 优化了播放控制逻辑

20. **增加了内容管理功能**
    - 新增内容删除功能（长按/右滑触发）
    - 添加删除确认机制

21. **修复了设置页面问题**
    - 实现了用户协议、隐私政策和联系我们的跳转功能

## 安装说明

1. 克隆项目
```bash
git clone https://github.com/yourusername/Yike.git
```