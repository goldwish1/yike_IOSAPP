#!/bin/bash

# 忆刻应用UI冒烟测试运行脚本
# 用法: ./run_ui_smoke_tests.sh [--report] [--verbose]

# 解析命令行参数
GENERATE_REPORT=false
VERBOSE=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --report) GENERATE_REPORT=true ;;
        --verbose) VERBOSE=true ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
    shift
done

# 设置颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 检查Xcode是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}错误: 未找到xcodebuild命令。请确保Xcode已安装并设置正确。${NC}"
    exit 1
fi

# 项目路径
PROJECT_DIR="/Users/fengyuanzhou/Desktop/IOS APP/Yike/Yike"
PROJECT_PATH="$PROJECT_DIR/Yike.xcodeproj"
TEST_PLAN_PATH="$PROJECT_DIR/YikeUITests/UISmokeTesting/YikeSmokeUITest.xctestplan"

echo -e "${GREEN}=== 开始忆刻应用UI冒烟测试 ===${NC}"
echo -e "${YELLOW}项目路径: ${PROJECT_DIR}${NC}"

# 获取可用的iOS模拟器
echo -e "${YELLOW}查找可用的模拟器...${NC}"
AVAILABLE_SIMULATORS=$(xcrun simctl list devices available -j | grep -E 'iPhone 12|iPhone 11' | grep -v unavailable | grep -v disabled | awk -F'"' '{print $4}' | head -n 1)
if [ -z "$AVAILABLE_SIMULATORS" ]; then
    AVAILABLE_SIMULATORS=$(xcrun simctl list devices available -j | grep "name" | grep -v unavailable | grep -v disabled | awk -F'"' '{print $4}' | head -n 1)
fi
SIMULATOR="$AVAILABLE_SIMULATORS"
echo -e "${GREEN}使用模拟器: $SIMULATOR${NC}"

# 设置构建目录
BUILD_DIR="$PROJECT_DIR/build"
mkdir -p "$BUILD_DIR"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
TEST_RESULTS_DIR="$DERIVED_DATA_PATH/Logs/Test"

# 设置测试计划
TEST_PLAN="YikeSmokeUITest"
DESTINATION="platform=iOS Simulator,name=$SIMULATOR"

# 设置命令
CMD="xcodebuild test -project \"$PROJECT_PATH\" \
-scheme Yike \
-testPlan YikeSmokeUITest \
-destination \"platform=iOS Simulator,name=$SIMULATOR\" \
-derivedDataPath \"$DERIVED_DATA_PATH\""

if [ "$VERBOSE" = false ]; then
    CMD="$CMD | xcbeautify"
fi

# 运行测试
echo -e "${YELLOW}运行UI冒烟测试...${NC}"
echo -e "${YELLOW}执行命令: $CMD${NC}"

if [ "$VERBOSE" = true ]; then
    eval "$CMD"
else
    if ! command -v xcbeautify &> /dev/null; then
        echo -e "${YELLOW}警告: 未找到xcbeautify。请安装它以获得更好的输出格式：brew install xcbeautify${NC}"
        eval "$CMD"
    else
        eval "$CMD"
    fi
fi

TEST_RESULT=$?

# 生成报告
if [ "$GENERATE_REPORT" = true ]; then
    echo -e "${YELLOW}生成测试报告...${NC}"
    
    # 找到最新的测试结果
    LATEST_TEST_RESULT=$(find "$TEST_RESULTS_DIR" -name "*.xcresult" -type d -depth 1 | sort -r | head -n 1)
    
    if [ -n "$LATEST_TEST_RESULT" ]; then
        # 生成HTML报告
        REPORT_DIR="$PROJECT_DIR/TestReports"
        mkdir -p "$REPORT_DIR"
        
        REPORT_PATH="$REPORT_DIR/UISmokeTesting_$(date +%Y%m%d_%H%M%S).html"
        
        xcrun xcresulttool get --format html --output "$REPORT_PATH" --path "$LATEST_TEST_RESULT"
        
        echo -e "${GREEN}测试报告已生成: $REPORT_PATH${NC}"
        
        # 尝试在浏览器中打开报告
        if [ -f "$REPORT_PATH" ]; then
            open "$REPORT_PATH"
        fi
    else
        echo -e "${RED}错误: 未找到测试结果文件${NC}"
    fi
fi

# 显示测试结果
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ UI冒烟测试成功完成!${NC}"
    exit 0
else
    echo -e "${RED}❌ UI冒烟测试失败!${NC}"
    exit 1
fi 