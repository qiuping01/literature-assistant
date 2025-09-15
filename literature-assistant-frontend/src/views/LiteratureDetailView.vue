<template>
  <div class="literature-detail-view">
    <!-- 加载状态 -->
    <div v-if="literatureStore.detailLoading" class="loading-container">
      <el-skeleton :rows="10" animated />
    </div>

    <!-- 错误状态 -->
    <el-alert
      v-else-if="literatureStore.error"
      :title="literatureStore.error"
      type="error"
      :closable="true"
      @close="literatureStore.clearError()"
      class="mb-24"
    />

    <!-- 详情内容 -->
    <div v-else-if="currentLiterature" class="detail-content">
      <!-- 导航栏 -->
      <div class="detail-header">
        <el-button @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回列表
        </el-button>
        <h2 class="detail-title">文献详情</h2>
      </div>

      <!-- 基本信息卡片 -->
      <el-card class="info-card mb-24" shadow="never">
        <template #header>
          <div class="card-header">
            <h3>基本信息</h3>
            <div class="header-actions">
              <el-dropdown v-if="isPdfFile(currentLiterature.fileType)" @command="handlePdfAction" trigger="click">
                <el-button type="primary" size="small">
                  <el-icon><Document /></el-icon>
                  PDF操作
                  <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="preview">
                      <el-icon><View /></el-icon>
                      浏览器预览
                    </el-dropdown-item>
                    <el-dropdown-item command="openLocal">
                      <el-icon><FolderOpened /></el-icon>
                      本地阅读器打开
                    </el-dropdown-item>
                    <el-dropdown-item command="download" divided>
                      <el-icon><Download /></el-icon>
                      下载文件
                    </el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
              <el-button
                v-else
                type="primary"
                size="small"
                @click="downloadFile"
                :loading="downloading"
              >
                <el-icon><Download /></el-icon>
                下载文件
              </el-button>
              <el-button
                type="danger"
                size="small"
                @click="deleteLiterature"
                :loading="deleting"
              >
                <el-icon><Delete /></el-icon>
                删除文献
              </el-button>
            </div>
          </div>
        </template>
        
        <el-row :gutter="24">
          <el-col :span="12">
            <div class="info-item">
              <label class="info-label">文件名：</label>
              <span 
                class="info-value file-name-link" 
                :class="{ 'clickable': isPdfFile(currentLiterature.fileType) }"
                :title="isPdfFile(currentLiterature.fileType) ? `点击预览 ${currentLiterature.originalName}` : currentLiterature.originalName"
                @click="handleFileNameClick"
              >
                <el-icon v-if="isPdfFile(currentLiterature.fileType)" class="file-icon">
                  <Document />
                </el-icon>
                {{ currentLiterature.originalName }}
              </span>
            </div>
          </el-col>
          <el-col :span="12">
            <div class="info-item">
              <label class="info-label">文件大小：</label>
              <span class="info-value">{{ formatFileSize(currentLiterature.fileSize) }}</span>
            </div>
          </el-col>
        </el-row>
        
        <el-row :gutter="24">
          <el-col :span="12">
            <div class="info-item">
              <label class="info-label">文件类型：</label>
              <el-tag size="small" type="info">{{ currentLiterature.fileType?.toUpperCase() }}</el-tag>
            </div>
          </el-col>
          <el-col :span="12">
            <div class="info-item">
              <label class="info-label">状态：</label>
              <el-tag
                size="small"
                :type="getStatusType(currentLiterature.status)"
              >
                {{ getStatusText(currentLiterature.status) }}
              </el-tag>
            </div>
          </el-col>
        </el-row>
        
        <el-row :gutter="24">
          <el-col :span="24">
            <div class="info-item">
              <label class="info-label">创建时间：</label>
              <span class="info-value">{{ formatDateTime(currentLiterature.createTime) }}</span>
            </div>
          </el-col>
        </el-row>
      </el-card>

      <!-- 标签卡片 -->
      <el-card class="tags-card mb-24" shadow="never">
        <template #header>
          <div class="card-header">
            <h3>标签</h3>
          </div>
        </template>
        
        <div class="tags-content">
          <el-tag
            v-for="tag in currentLiterature.tags"
            :key="tag"
            class="tag-item"
            size="large"
          >
            {{ tag }}
          </el-tag>
          <span v-if="!currentLiterature.tags || currentLiterature.tags.length === 0" class="no-tags">
            暂无标签
          </span>
        </div>
      </el-card>

      <!-- 描述卡片 -->
      <el-card class="description-card mb-24" shadow="never">
        <template #header>
          <div class="card-header">
            <h3>描述</h3>
          </div>
        </template>
        
        <div class="description-content">
          <p v-if="currentLiterature.description" class="description-text">
            {{ currentLiterature.description }}
          </p>
          <p v-else class="no-description">暂无描述</p>
        </div>
      </el-card>

      <!-- 阅读指南卡片 -->
      <el-card class="guide-card" shadow="never">
        <template #header>
          <div class="card-header">
            <h3>AI 阅读指南</h3>
            <el-button
              v-if="currentLiterature.readingGuideSummary"
              size="small"
              @click="toggleFullscreen"
            >
              <el-icon><FullScreen /></el-icon>
              {{ isFullscreen ? '退出全屏' : '全屏阅读' }}
            </el-button>
          </div>
        </template>
        
        <div
          ref="guideContentRef"
          class="guide-content"
          :class="{ 'fullscreen': isFullscreen }"
        >
          <!-- 全屏模式下的退出按钮 -->
          <div v-if="isFullscreen" class="fullscreen-header">
            <h3 class="fullscreen-title">AI 阅读指南</h3>
            <el-button
              type="default"
              size="small"
              @click="toggleFullscreen"
              class="exit-fullscreen-btn"
            >
              <el-icon><Close /></el-icon>
              退出全屏
            </el-button>
          </div>
                      <div
              v-if="currentLiterature.readingGuideSummary"
              class="markdown-content"
              v-html="renderedGuide"
            ></div>
          <div v-else class="no-guide">
            <el-empty description="暂无阅读指南" />
          </div>
        </div>
      </el-card>
    </div>

    <!-- 未找到文献 -->
    <el-empty v-else description="未找到该文献" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watchEffect } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useLiteratureStore } from '@/stores/literatureStore'
import { ElMessage } from 'element-plus'
import { marked } from 'marked'
import mermaid from 'mermaid'
import { ArrowLeft, FullScreen, Close, Download, Document, ArrowDown, View, FolderOpened, Delete } from '@element-plus/icons-vue'
import { ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()
const literatureStore = useLiteratureStore()

// 响应式数据
const guideContentRef = ref()
const isFullscreen = ref(false)
const downloading = ref(false)
const deleting = ref(false)

// 计算属性
const currentLiterature = computed(() => literatureStore.currentLiterature)

const renderedGuide = computed(() => {
  if (!currentLiterature.value?.readingGuideSummary) return ''
  
  try {
    // 配置 marked
    marked.setOptions({
      breaks: true,
      gfm: true
    })
    
    return marked(currentLiterature.value.readingGuideSummary)
  } catch (error) {
    console.error('Markdown 渲染错误:', error)
    return currentLiterature.value.readingGuideSummary
  }
})

// 方法
const goBack = () => {
  router.push('/')
}

const formatFileSize = (bytes) => {
  if (!bytes || bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const formatDateTime = (dateTime) => {
  if (!dateTime) return '-'
  return new Date(dateTime).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

const getStatusType = (status) => {
  const statusMap = {
    0: 'warning',
    1: 'success',
    2: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status) => {
  const statusMap = {
    0: '处理中',
    1: '已完成',
    2: '失败'
  }
  return statusMap[status] || '未知'
}

const toggleFullscreen = () => {
  isFullscreen.value = !isFullscreen.value
  
  if (isFullscreen.value) {
    document.body.style.overflow = 'hidden'
    // 添加ESC键监听
    document.addEventListener('keydown', handleEscapeKey)
  } else {
    document.body.style.overflow = ''
    // 移除ESC键监听
    document.removeEventListener('keydown', handleEscapeKey)
  }
}

// ESC键退出全屏
const handleEscapeKey = (event) => {
  if (event.key === 'Escape' && isFullscreen.value) {
    toggleFullscreen()
  }
}

// 判断是否为PDF文件
const isPdfFile = (fileType) => {
  return fileType && fileType.toLowerCase() === 'pdf'
}

// 处理文件名点击
const handleFileNameClick = () => {
  if (!currentLiterature.value) return
  
  if (isPdfFile(currentLiterature.value.fileType)) {
    // PDF文件直接预览
    previewPdfFile()
  }
}

// 预览PDF文件
const previewPdfFile = () => {
  if (!currentLiterature.value) return
  
  try {
    // 构建预览URL - 添加时间戳防止缓存，确保显示最新内容（包括标注高亮）
    const timestamp = new Date().getTime()
    const previewUrl = `/api/literature/${currentLiterature.value.id}/preview?t=${timestamp}`
    
    // 在新窗口中打开PDF预览
    const newWindow = window.open(previewUrl, '_blank', 'width=1200,height=800,scrollbars=yes,resizable=yes')
    
    if (!newWindow) {
      // 如果弹窗被阻止，提示用户
      ElMessage.warning('请允许弹窗以预览PDF文件')
    } else {
      // 设置新窗口标题
      newWindow.document.title = `预览 - ${currentLiterature.value.originalName}`
    }
  } catch (error) {
    console.error('预览PDF文件失败:', error)
    ElMessage.error('预览PDF文件失败，请重试')
  }
}

// 使用本地PDF阅读器打开
const openWithLocalReader = async () => {
  if (!currentLiterature.value) return
  
  try {
    // 获取文件本地路径
    const response = await fetch(`/api/literature/${currentLiterature.value.id}/local-path`)
    const result = await response.json()
    
    if (!result.success) {
      throw new Error(result.message || '获取文件路径失败')
    }
    
    const localPath = result.data
    
    // 检测操作系统并使用相应的方法打开文件
    const userAgent = navigator.userAgent.toLowerCase()
    
    if (userAgent.includes('win')) {
      // Windows系统
      await openFileOnWindows(localPath, currentLiterature.value.originalName)
    } else if (userAgent.includes('mac')) {
      // macOS系统
      await openFileOnMac(localPath, currentLiterature.value.originalName)
    } else {
      // Linux或其他系统
      await openFileOnLinux(localPath, currentLiterature.value.originalName)
    }
    
  } catch (error) {
    console.error('使用本地阅读器打开失败:', error)
    ElMessage.error(`无法使用本地阅读器打开文件: ${error.message}`)
  }
}

// Windows系统打开文件
const openFileOnWindows = async (filePath, fileName) => {
  try {
    // 方法1: 尝试使用file://协议
    const fileUrl = `file:///${filePath.replace(/\\/g, '/')}`
    const newWindow = window.open(fileUrl, '_blank')
    
    if (!newWindow) {
      // 方法2: 创建下载链接并提示用户
      showLocalOpenInstructions(filePath, fileName, 'Windows')
    } else {
      ElMessage.success('正在使用默认PDF阅读器打开文件...')
    }
  } catch (error) {
    showLocalOpenInstructions(filePath, fileName, 'Windows')
  }
}

// macOS系统打开文件
const openFileOnMac = async (filePath, fileName) => {
  try {
    // 尝试使用file://协议
    const fileUrl = `file://${filePath}`
    const newWindow = window.open(fileUrl, '_blank')
    
    if (!newWindow) {
      showLocalOpenInstructions(filePath, fileName, 'macOS')
    } else {
      ElMessage.success('正在使用默认PDF阅读器打开文件...')
    }
  } catch (error) {
    showLocalOpenInstructions(filePath, fileName, 'macOS')
  }
}

// Linux系统打开文件
const openFileOnLinux = async (filePath, fileName) => {
  try {
    // 尝试使用file://协议
    const fileUrl = `file://${filePath}`
    const newWindow = window.open(fileUrl, '_blank')
    
    if (!newWindow) {
      showLocalOpenInstructions(filePath, fileName, 'Linux')
    } else {
      ElMessage.success('正在使用默认PDF阅读器打开文件...')
    }
  } catch (error) {
    showLocalOpenInstructions(filePath, fileName, 'Linux')
  }
}

// 显示本地打开说明
const showLocalOpenInstructions = (filePath, fileName, os) => {
  let instructions = ''
  
  switch (os) {
    case 'Windows':
      instructions = `
        <p>由于浏览器安全限制，请手动打开以下路径的文件：</p>
        <div style="background: #f5f5f5; padding: 10px; border-radius: 4px; position: relative; margin: 10px 0;">
          <div style="word-break: break-all; font-family: monospace; padding-right: 80px;">
            ${filePath}
          </div>
          <button id="copyPathBtn" style="position: absolute; top: 8px; right: 8px; padding: 4px 8px; background: #409eff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 12px;">
            📋 复制路径
          </button>
        </div>
        <p><strong>💡 重要提示：</strong>在本地PDF阅读器中对文件进行的标注、高亮等操作会直接保存到此文件，无需额外同步到文献助手。</p>
        <p>您可以：</p>
        <ul>
          <li>点击上方 <strong>📋 复制路径</strong> 按钮，然后按 <kbd>Win+R</kbd> 粘贴并回车</li>
          <li>复制路径后在文件资源管理器地址栏中粘贴</li>
          <li>手动导航到该路径</li>
        </ul>
      `
      break
    case 'macOS':
      instructions = `
        <p>由于浏览器安全限制，请手动打开以下路径的文件：</p>
        <div style="background: #f5f5f5; padding: 10px; border-radius: 4px; position: relative; margin: 10px 0;">
          <div style="word-break: break-all; font-family: monospace; padding-right: 80px;">
            ${filePath}
          </div>
          <button id="copyPathBtn" style="position: absolute; top: 8px; right: 8px; padding: 4px 8px; background: #409eff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 12px;">
            📋 复制路径
          </button>
        </div>
        <p><strong>💡 重要提示：</strong>在本地PDF阅读器中对文件进行的标注、高亮等操作会直接保存到此文件，无需额外同步到文献助手。</p>
        <p>您可以：</p>
        <ul>
          <li>点击上方 <strong>📋 复制路径</strong> 按钮，然后按 <kbd>Cmd+Shift+G</kbd> 在Finder中粘贴</li>
          <li>按 <kbd>Cmd+Space</kbd> 打开Spotlight，输入文件名搜索</li>
          <li>使用终端: <code>open "${filePath}"</code></li>
        </ul>
      `
      break
    case 'Linux':
      instructions = `
        <p>由于浏览器安全限制，请手动打开以下路径的文件：</p>
        <div style="background: #f5f5f5; padding: 10px; border-radius: 4px; position: relative; margin: 10px 0;">
          <div style="word-break: break-all; font-family: monospace; padding-right: 80px;">
            ${filePath}
          </div>
          <button id="copyPathBtn" style="position: absolute; top: 8px; right: 8px; padding: 4px 8px; background: #409eff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 12px;">
            📋 复制路径
          </button>
        </div>
        <p><strong>💡 重要提示：</strong>在本地PDF阅读器中对文件进行的标注、高亮等操作会直接保存到此文件，无需额外同步到文献助手。</p>
        <p>您可以：</p>
        <ul>
          <li>点击上方 <strong>📋 复制路径</strong> 按钮，然后在文件管理器地址栏中粘贴</li>
          <li>使用终端: <code>xdg-open "${filePath}"</code></li>
          <li>或者: <code>evince "${filePath}"</code> (如果安装了Evince)</li>
        </ul>
      `
      break
  }
  
  ElMessageBox.alert(instructions, `打开文件 - ${fileName}`, {
    dangerouslyUseHTMLString: true,
    confirmButtonText: '我知道了',
    type: 'info',
    customStyle: {
      width: '600px'
    }
  }).then(() => {
    // 弹窗关闭后的回调
  }).catch(() => {
    // 用户取消的回调
  })
  
  // 等待DOM更新后绑定复制按钮事件
  setTimeout(() => {
    const copyBtn = document.getElementById('copyPathBtn')
    if (copyBtn) {
      copyBtn.onclick = () => {
        copyToClipboard(filePath)
      }
    }
  }, 100)
}

// 复制文本到剪贴板
const copyToClipboard = async (text) => {
  try {
    if (navigator.clipboard && window.isSecureContext) {
      // 使用现代 Clipboard API
      await navigator.clipboard.writeText(text)
      ElMessage.success('路径已复制到剪贴板！')
    } else {
      // 降级方案：使用传统方法
      const textArea = document.createElement('textarea')
      textArea.value = text
      textArea.style.position = 'fixed'
      textArea.style.left = '-999999px'
      textArea.style.top = '-999999px'
      document.body.appendChild(textArea)
      textArea.focus()
      textArea.select()
      
      try {
        document.execCommand('copy')
        ElMessage.success('路径已复制到剪贴板！')
      } catch (err) {
        ElMessage.error('复制失败，请手动复制路径')
      } finally {
        document.body.removeChild(textArea)
      }
    }
  } catch (err) {
    console.error('复制失败:', err)
    ElMessage.error('复制失败，请手动复制路径')
  }
}

// 处理PDF操作
const handlePdfAction = (command) => {
  switch (command) {
    case 'preview':
      previewPdfFile()
      break
    case 'openLocal':
      openWithLocalReader()
      break
    case 'download':
      downloadFile()
      break
  }
}

// 下载文件
const downloadFile = async () => {
  if (!currentLiterature.value || downloading.value) {
    return
  }

  try {
    downloading.value = true
    
    // 创建下载链接
    const downloadUrl = `/api/literature/${currentLiterature.value.id}/download`
    
    // 使用fetch检查文件是否存在
    const response = await fetch(downloadUrl, { method: 'HEAD' })
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    // 创建临时链接进行下载
    const link = document.createElement('a')
    link.href = downloadUrl
    link.download = currentLiterature.value.originalName || '文献文件'
    link.style.display = 'none'
    
    // 添加到页面并触发下载
    document.body.appendChild(link)
    link.click()
    
    // 清理
    document.body.removeChild(link)
    
    // 提示下载开始
    ElMessage.success('文件下载已开始')
    
  } catch (error) {
    console.error('下载文件失败:', error)
    
    // 根据错误类型显示不同的提示
    let errorMessage = '下载文件失败，请重试'
    if (error.message.includes('404')) {
      errorMessage = '文件不存在或已被删除'
    } else if (error.message.includes('403')) {
      errorMessage = '没有权限下载该文件'
    } else if (error.message.includes('500')) {
      errorMessage = '服务器错误，请稍后重试'
    }
    
    ElMessage.error(errorMessage)
  } finally {
    downloading.value = false
  }
}

// 删除文献
const deleteLiterature = async () => {
  if (!currentLiterature.value || deleting.value) {
    return
  }

  try {
    // 显示确认对话框
    await ElMessageBox.confirm(
      `确定要删除文献 "${currentLiterature.value.originalName}" 吗？此操作将永久删除文件和相关数据，不可撤销。`,
      '删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning',
        confirmButtonClass: 'el-button--danger'
      }
    )

    deleting.value = true

    // 调用store中的删除方法
    await literatureStore.deleteLiterature(currentLiterature.value.id)

    // 删除成功提示
    ElMessage.success('文献删除成功')
    
    // 返回到文献列表页面
    router.push('/')
    
  } catch (error) {
    // 用户取消删除
    if (error === 'cancel') {
      return
    }
    
    console.error('删除文献失败:', error)
    
    // 根据错误类型显示不同的提示
    let errorMessage = '删除文献失败，请重试'
    if (error.message) {
      errorMessage = error.message
    }
    
    ElMessage.error(errorMessage)
  } finally {
    deleting.value = false
  }
}

// HTML 转义函数
const escapeHtml = (text) => {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

// 验证 Mermaid 语法
const isValidMermaidSyntax = (code) => {
  if (!code || typeof code !== 'string') return false
  
  const trimmedCode = code.trim()
  if (!trimmedCode) return false
  
  // 基本语法检查
  const validDiagramTypes = [
    'graph', 'flowchart', 'sequenceDiagram', 'classDiagram', 
    'stateDiagram', 'erDiagram', 'journey', 'gantt', 'pie',
    'gitgraph', 'mindmap', 'timeline', 'quadrantChart'
  ]
  
  // 检查是否以有效的图表类型开始
  const firstLine = trimmedCode.split('\n')[0].trim().toLowerCase()
  const hasValidStart = validDiagramTypes.some(type => 
    firstLine.startsWith(type.toLowerCase())
  )
  
  if (!hasValidStart) return false
  
  // 检查常见的语法问题
  const lines = trimmedCode.split('\n')
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    if (!line) continue
    
    // 检查是否包含无效字符或格式
    // 避免包含数字开头的节点ID（这是常见的错误来源）
    if (line.includes('|') && line.includes('[')) {
      // 检查节点定义中的问题
      const nodeMatch = line.match(/(\w+)\s*\[([^\]]*)\]/)
      if (nodeMatch) {
        const nodeId = nodeMatch[1]
        const nodeText = nodeMatch[2]
        
        // 节点ID不能以数字开头
        if (/^\d/.test(nodeId)) return false
        
        // 检查节点文本中是否包含未闭合的标签
        if (nodeText.includes('<') && !nodeText.includes('>')) return false
      }
    }
    
    // 检查箭头语法
    if (line.includes('-->') || line.includes('->')) {
      // 确保箭头两边都有有效的节点
      const arrowParts = line.split(/-->|->/)
      if (arrowParts.length !== 2) continue
      
      const leftPart = arrowParts[0].trim()
      const rightPart = arrowParts[1].trim()
      
      if (!leftPart || !rightPart) return false
    }
  }
  
  return true
}

// 渲染 Mermaid 图表
const renderMermaidCharts = async () => {
  await nextTick()
  
  if (!guideContentRef.value) return
  
  // 查找所有 mermaid 代码块
  const mermaidBlocks = guideContentRef.value.querySelectorAll('pre code.language-mermaid, code.language-mermaid')
  
  for (let i = 0; i < mermaidBlocks.length; i++) {
    const block = mermaidBlocks[i]
    const code = block.textContent || block.innerText
    
    try {
      // 预验证 Mermaid 语法
      if (!isValidMermaidSyntax(code)) {
        throw new Error('Invalid Mermaid syntax')
      }
      
      // 创建容器
      const container = document.createElement('div')
      container.className = 'mermaid-container'
      container.id = `mermaid-${Date.now()}-${i}`
      
      // 渲染图表
      const { svg } = await mermaid.render(container.id, code)
      container.innerHTML = svg
      
      // 替换原来的代码块
      const parent = block.parentElement
      if (parent && parent.tagName === 'PRE' && parent.parentNode) {
        parent.parentNode.replaceChild(container, parent)
      } else if (block.parentNode) {
        block.parentNode.replaceChild(container, block)
      }
    } catch (error) {
      console.error('Mermaid 渲染错误:', error)
      
      // 渲染失败时显示友好的错误提示
      const errorContainer = document.createElement('div')
      errorContainer.className = 'mermaid-error-container'
      errorContainer.innerHTML = `
        <div class="mermaid-error">
          <p>图表渲染失败</p>
          <details>
            <summary>查看详情</summary>
            <pre><code>${escapeHtml(code)}</code></pre>
          </details>
        </div>
      `
      
      // 替换原来的代码块
      const parent = block.parentElement
      if (parent && parent.tagName === 'PRE' && parent.parentNode) {
        parent.parentNode.replaceChild(errorContainer, parent)
      } else if (block.parentNode) {
        block.parentNode.replaceChild(errorContainer, block)
      }
    }
  }
}

// 监听渲染指南变化，重新渲染 Mermaid 图表
const handleGuideRendered = async () => {
  if (renderedGuide.value) {
    await nextTick()
    await renderMermaidCharts()
  }
}

// 生命周期
onMounted(async () => {
  // 初始化 Mermaid
  mermaid.initialize({
    startOnLoad: false,
    theme: 'default',
    securityLevel: 'loose',
    fontFamily: 'Arial, sans-serif',
    suppressErrorRendering: true, // 抑制错误渲染
    logLevel: 'fatal', // 只记录致命错误
    // 自定义错误处理
    errorCallback: (error) => {
      console.error('Mermaid 详情页错误:', error)
      return false // 阻止默认错误处理
    }
  })
  
  // 获取文献详情
  const literatureId = route.params.id
  if (literatureId) {
    await literatureStore.fetchLiteratureDetail(literatureId)
    await handleGuideRendered()
  }
})

onUnmounted(() => {
  // 清理全屏状态
  if (isFullscreen.value) {
    document.body.style.overflow = ''
    // 清理ESC键监听
    document.removeEventListener('keydown', handleEscapeKey)
  }
  
  // 清理当前文献数据
  literatureStore.clearCurrentLiterature()
})

// 监听渲染指南变化

const stopWatching = watchEffect(() => {
  if (renderedGuide.value) {
    handleGuideRendered()
  }
})

onUnmounted(() => {
  stopWatching()
})
</script>

<style scoped>
.literature-detail-view {
  max-width: 1200px;
  margin: 0 auto;
}

.loading-container {
  padding: 24px;
}

.detail-header {
  display: flex;
  align-items: center;
  margin-bottom: 24px;
}

.back-button {
  margin-right: 16px;
}

.detail-title {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #2c3e50;
}

.info-card,
.tags-card,
.description-card,
.guide-card {
  border: 1px solid #ebeef5;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.info-item {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.info-item:last-child {
  margin-bottom: 0;
}

.info-label {
  min-width: 80px;
  font-weight: 500;
  color: #606266;
  margin-right: 8px;
}

.info-value {
  color: #303133;
  word-break: break-all;
}

.file-name-link {
  display: flex;
  align-items: center;
  gap: 6px;
}

.file-name-link.clickable {
  cursor: pointer;
  color: #409eff;
  transition: all 0.2s ease;
}

.file-name-link.clickable:hover {
  color: #66b1ff;
  text-decoration: underline;
}

.file-icon {
  font-size: 14px;
  color: #f56c6c;
}

.tags-content {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-item {
  margin: 0;
}

.no-tags {
  color: #909399;
  font-size: 14px;
}

.description-content {
  line-height: 1.6;
}

.description-text {
  margin: 0;
  color: #303133;
  white-space: pre-wrap;
}

.no-description {
  margin: 0;
  color: #909399;
  font-style: italic;
}

.guide-content {
  position: relative;
  transition: all 0.3s ease;
}

.guide-content.fullscreen {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  background: white;
  padding: 0;
  overflow-y: auto;
}

.fullscreen-header {
  position: sticky;
  top: 0;
  background: white;
  border-bottom: 1px solid #ebeef5;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
}

.fullscreen-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #2c3e50;
}

.exit-fullscreen-btn {
  position: relative;
}

.guide-content.fullscreen .markdown-content {
  padding: 24px;
}

.markdown-content {
  line-height: 1.8;
  color: #333;
  font-size: 14px;
}

.markdown-content :deep(h1) {
  font-size: 28px;
  margin: 24px 0 16px 0;
  padding-bottom: 12px;
  border-bottom: 2px solid #eee;
  color: #2c3e50;
}

.markdown-content :deep(h2) {
  font-size: 24px;
  margin: 20px 0 12px 0;
  padding-bottom: 8px;
  border-bottom: 1px solid #eee;
  color: #2c3e50;
}

.markdown-content :deep(h3) {
  font-size: 20px;
  margin: 16px 0 8px 0;
  color: #2c3e50;
}

.markdown-content :deep(h4) {
  font-size: 18px;
  margin: 14px 0 6px 0;
  color: #2c3e50;
}

.markdown-content :deep(h5),
.markdown-content :deep(h6) {
  font-size: 16px;
  margin: 12px 0 4px 0;
  color: #2c3e50;
}

.markdown-content :deep(p) {
  margin: 12px 0;
  line-height: 1.8;
}

.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  margin: 12px 0;
  padding-left: 24px;
}

.markdown-content :deep(li) {
  margin: 6px 0;
  line-height: 1.6;
}

.markdown-content :deep(blockquote) {
  margin: 16px 0;
  padding: 12px 20px;
  background-color: #f8f9fa;
  border-left: 4px solid #409eff;
  color: #6c757d;
}

.markdown-content :deep(code) {
  background-color: #f8f9fa;
  padding: 3px 6px;
  border-radius: 4px;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.9em;
  color: #e83e8c;
}

.markdown-content :deep(pre) {
  background-color: #f8f9fa;
  padding: 16px;
  border-radius: 6px;
  overflow-x: auto;
  margin: 16px 0;
  border: 1px solid #e9ecef;
}

.markdown-content :deep(pre code) {
  background: none;
  padding: 0;
  color: #333;
}

.markdown-content :deep(table) {
  width: 100%;
  border-collapse: collapse;
  margin: 16px 0;
  border: 1px solid #ddd;
}

.markdown-content :deep(th),
.markdown-content :deep(td) {
  padding: 8px 12px;
  border: 1px solid #ddd;
  text-align: left;
}

.markdown-content :deep(th) {
  background-color: #f5f7fa;
  font-weight: 600;
}

.no-guide {
  text-align: center;
  padding: 40px 0;
}

.mb-24 {
  margin-bottom: 24px;
}

/* Mermaid 图表样式 */
.markdown-content :deep(.mermaid-container) {
  text-align: center;
  margin: 24px 0;
  padding: 20px;
  background: #fafafa;
  border: 1px solid #eee;
  border-radius: 8px;
   /* 新增：重置行高，防止继承父级导致样式冲突 */
  line-height: normal;
}

.markdown-content :deep(.mermaid-container svg) {
  max-width: 100%;
  height: auto;
}

/* Mermaid 错误处理样式 */
.markdown-content :deep(.mermaid-error-container) {
  margin: 16px 0;
  border-radius: 8px;
  overflow: hidden;
}

.markdown-content :deep(.mermaid-error) {
  background-color: #fff7e6;
  border: 1px solid #ffd591;
  border-radius: 6px;
  padding: 16px;
}

.markdown-content :deep(.mermaid-error p) {
  color: #d46b08;
  margin: 0 0 8px 0;
  font-weight: 500;
  font-size: 14px;
}

.markdown-content :deep(.mermaid-error details) {
  margin-top: 8px;
}

.markdown-content :deep(.mermaid-error summary) {
  color: #d46b08;
  cursor: pointer;
  font-size: 12px;
  margin-bottom: 8px;
}

.markdown-content :deep(.mermaid-error pre) {
  background-color: #f5f5f5;
  padding: 12px;
  border-radius: 4px;
  overflow-x: auto;
  margin: 8px 0 0 0;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 12px;
  line-height: 1.4;
  color: #333;
  max-height: 200px;
  overflow-y: auto;
}
</style>
