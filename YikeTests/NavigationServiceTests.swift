//
//  NavigationServiceTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class NavigationServiceTests: YikeBaseTests {
    
    // 被测试的服务
    var navigationService: NavigationService!
    var navigationRouter: NavigationRouter!
    
    override func setUp() {
        super.setUp()
        
        // 初始化导航服务
        navigationRouter = NavigationRouter()
        navigationService = NavigationService(router: navigationRouter)
    }
    
    // MARK: - 测试基本功能
    
    func testInitialState() {
        // 验证初始状态
        XCTAssertEqual(navigationRouter.navigationPath.count, 0)
        XCTAssertFalse(navigationRouter.isPresenting)
    }
    
    // MARK: - 测试导航功能
    
    func testNavigateToDestination() {
        // 导航到特定页面
        navigationService.navigateTo(.settings)
        
        // 验证导航路径已更新
        XCTAssertEqual(navigationRouter.navigationPath.count, 1)
        // 验证路径中的目标是正确的
        XCTAssertEqual(navigationRouter.navigationPath.last, .settings)
    }
    
    func testNavigateBack() {
        // 首先导航到某个页面
        navigationService.navigateTo(.settings)
        XCTAssertEqual(navigationRouter.navigationPath.count, 1)
        
        // 然后返回
        navigationService.navigateBack()
        
        // 验证导航路径已更新
        XCTAssertEqual(navigationRouter.navigationPath.count, 0)
    }
    
    func testNavigateToRoot() {
        // 导航到多个页面
        navigationService.navigateTo(.settings)
        navigationService.navigateTo(.playSettings)
        navigationService.navigateTo(.reminderSettings)
        XCTAssertEqual(navigationRouter.navigationPath.count, 3)
        
        // 返回到根页面
        navigationService.navigateToRoot()
        
        // 验证导航路径已重置
        XCTAssertEqual(navigationRouter.navigationPath.count, 0)
    }
    
    func testPresentSheet() {
        // 使用表单模式展示页面
        navigationService.presentSheet(.pointsCenter)
        
        // 验证状态
        XCTAssertTrue(navigationRouter.isPresenting)
        XCTAssertEqual(navigationRouter.presentedDestination, .pointsCenter)
    }
    
    func testDismissSheet() {
        // 首先展示表单
        navigationService.presentSheet(.pointsCenter)
        XCTAssertTrue(navigationRouter.isPresenting)
        
        // 然后关闭表单
        navigationService.dismissSheet()
        
        // 验证状态
        XCTAssertFalse(navigationRouter.isPresenting)
        XCTAssertNil(navigationRouter.presentedDestination)
    }
    
    // MARK: - 测试iOS版本兼容性
    
    func testVersionCompatibility() {
        // 测试iOS 16+和iOS 16以下版本的兼容性
        // 这需要特定的测试设置，可能需要模拟不同的iOS版本
    }
} 