# 文献助手快速启动脚本 (PowerShell)
# 适用于 Node22 + Java21 环境

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "           文献助手 - 快速启动 (Node22 + Java21)" -ForegroundColor Green  
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# 检查Java环境
Write-Host "[检查] 验证Java21环境..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "21"
    if ($javaVersion) {
        Write-Host "[✓] Java21环境正常" -ForegroundColor Green
    } else {
        Write-Host "[警告] 当前Java版本可能不是21，但继续启动..." -ForegroundColor Yellow
        java -version
    }
} catch {
    Write-Host "[错误] Java未安装或不在PATH中" -ForegroundColor Red
    exit 1
}

# 检查Node环境  
Write-Host "[检查] 验证Node22环境..." -ForegroundColor Yellow
try {
    $nodeVersion = node -v
    if ($nodeVersion -like "*v22*") {
        Write-Host "[✓] Node22环境正常" -ForegroundColor Green
    } else {
        Write-Host "[警告] 当前Node版本: $nodeVersion，推荐使用v22" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[错误] Node.js未安装或不在PATH中" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 检查后端JAR文件
$jarPath = "jar\literature-assistant-0.0.1-SNAPSHOT.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "[错误] 后端JAR文件不存在: $jarPath" -ForegroundColor Red
    Write-Host "请先构建项目: mvn clean package -DskipTests" -ForegroundColor Yellow
    Read-Host "按Enter键退出"
    exit 1
}

# 启动后端
Write-Host "[启动] 后端服务 (Spring Boot)..." -ForegroundColor Yellow
Start-Process -FilePath "cmd" -ArgumentList "/k", "echo 后端启动中... && java -jar $jarPath" -WindowStyle Normal
Write-Host "[✓] 后端服务已在新窗口启动" -ForegroundColor Green

# 等待后端启动
Write-Host "[等待] 后端服务启动中..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# 启动前端
Write-Host "[启动] 前端服务 (Vue + Vite)..." -ForegroundColor Yellow
Set-Location "literature-assistant-frontend"

# 检查前端依赖
if (-not (Test-Path "node_modules")) {
    Write-Host "[安装] 前端依赖安装中..." -ForegroundColor Yellow
    npm install
}

Start-Process -FilePath "cmd" -ArgumentList "/k", "echo 前端启动中... && npm run dev" -WindowStyle Normal
Set-Location ".."
Write-Host "[✓] 前端服务已在新窗口启动" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "[完成] 服务启动完成！" -ForegroundColor Green
Write-Host ""
Write-Host "后端地址: http://localhost:8080" -ForegroundColor Cyan
Write-Host "前端地址: http://localhost:5173" -ForegroundColor Cyan  
Write-Host "API文档: http://localhost:8080/doc.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "按任意键关闭此窗口..." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green

Read-Host