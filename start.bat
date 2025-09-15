@echo off
chcp 65001 > nul

echo ==========================================================
echo            文献助手 - 快速启动
echo ==========================================================
echo.

:: 启动后端 (Spring Boot)
echo [1/2] 启动后端服务...
start "文献助手-后端" cmd /k "java -jar jar\literature-assistant-0.0.1-SNAPSHOT.jar"
echo [✓] 后端服务已启动 (端口: 8086)

:: 等待后端启动
timeout /t 8 > nul

:: 启动前端 (Vue)
echo [2/2] 启动前端服务...
cd literature-assistant-frontend
start "文献助手-前端" cmd /k "npm run dev"
cd ..
echo [✓] 前端服务已启动 (端口: 5173)

echo.
echo ==========================================================
echo [完成] 服务启动完成！
echo.
echo 🌐 前端地址: http://localhost:5173
echo 🔧 后端地址: http://localhost:8086/api  
echo 📚 API文档: http://localhost:8086/api/doc.html
echo.
echo 💡 提示: 关闭对应窗口即可停止服务
echo ==========================================================
pause