@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ==========================================================
echo            文献助手 - 快速启动 (Node22 + Java21)
echo ==========================================================
echo.

:: 检查Java版本
echo [检查] 验证Java21环境...
java -version 2>&1 | findstr "21" > nul
if %errorlevel% neq 0 (
    echo [警告] 当前Java版本可能不是21，但继续启动...
    java -version
) else (
    echo [✓] Java21环境正常
)
echo.

:: 检查Node版本
echo [检查] 验证Node22环境...
node -v 2>&1 | findstr "v22" > nul
if %errorlevel% neq 0 (
    echo [警告] 当前Node版本可能不是22，但继续启动...
    node -v
) else (
    echo [✓] Node22环境正常
)
echo.

:: 启动后端
echo [启动] 后端服务 (Spring Boot)...
if not exist "jar\literature-assistant-0.0.1-SNAPSHOT.jar" (
    echo [错误] 后端JAR文件不存在，请先构建项目
    echo 运行: mvn clean package -DskipTests
    pause
    exit /b 1
)

start "Literature-Backend" cmd /k "echo 后端启动中... && java -jar jar\literature-assistant-0.0.1-SNAPSHOT.jar"
echo [✓] 后端服务已在新窗口启动
echo.

:: 等待后端启动
echo [等待] 后端服务启动中...
timeout /t 8 > nul

:: 启动前端
echo [启动] 前端服务 (Vue + Vite)...
cd literature-assistant-frontend

:: 检查依赖
if not exist "node_modules" (
    echo [安装] 前端依赖安装中...
    npm install
)

start "Literature-Frontend" cmd /k "echo 前端启动中... && npm run dev"
cd ..
echo [✓] 前端服务已在新窗口启动
echo.

echo ==========================================================
echo [完成] 服务启动完成！
echo.
echo 后端地址: http://localhost:8080
echo 前端地址: http://localhost:5173
echo API文档: http://localhost:8080/doc.html
echo.
echo 按任意键关闭此窗口...
echo ==========================================================
pause > nul