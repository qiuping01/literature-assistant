<template>
  <div class="literature-list-view">
    <!-- 页面标题和导入按钮 -->
    <div class="page-header">
        <div class="header-left">
          <h2 class="page-title">文献管理<span class="page-slogan">智能管理您的学术文献，支持PDF上传、标签分类、全文搜索，让文献整理更高效</span></h2>
        </div>
        <div class="import-buttons">
          <el-button type="success" size="large" @click="showBatchImportModal = true">
            <el-icon><Upload /></el-icon>
            批量导入
          </el-button>
          <el-button type="primary" size="large" @click="showImportModal = true">
            <el-icon><Plus /></el-icon>
            单个导入
          </el-button>
        </div>
    </div>

    <!-- 错误提示 -->
    <el-alert
      v-if="literatureStore.error"
      :title="literatureStore.error"
      type="error"
      :closable="true"
      @close="literatureStore.clearError()"
      class="mb-16"
    />

    <!-- 筛选区域 -->
    <el-card class="filter-card mb-24" shadow="never">
      <el-form :model="queryParams" inline class="filter-form">
        <el-form-item label="关键词">
          <el-input
            v-model="queryParams.keyword"
            placeholder="搜索文献名称或描述"
            clearable
            style="width: 200px"
            @keyup.enter="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        
        <el-form-item label="标签">
          <el-select
            v-model="queryParams.tags"
            placeholder="选择标签"
            multiple
            clearable
            style="width: 200px"
          >
            <el-option
              v-for="tag in literatureStore.availableTags"
              :key="tag.value"
              :label="tag.label"
              :value="tag.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="文件类型">
          <el-select
            v-model="queryParams.fileType"
            placeholder="选择文件类型"
            clearable
            style="width: 150px"
          >
            <el-option
              v-for="type in literatureStore.availableFileTypes"
              :key="type.value"
              :label="type.label"
              :value="type.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="创建时间">
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            style="width: 240px"
            @change="handleDateRangeChange"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="handleSearch">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="handleReset">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 文献表格 -->
    <el-card shadow="never">
      <el-table
        :data="literatureStore.literatureList"
        :loading="literatureStore.loading"
        stripe
        @row-click="handleRowClick"
        style="width: 100%"
        class="literature-table"
        :header-cell-style="{ textAlign: 'center' }"
        :cell-style="{ textAlign: 'center' }"
      >
        <el-table-column prop="originalName" label="文件名" min-width="200">
          <template #default="{ row }">
            <div 
              class="file-name" 
              :class="{ 'clickable': isPdfFile(row.fileType) }"
              :title="isPdfFile(row.fileType) ? `点击预览 ${row.originalName}` : row.originalName"
              @click.stop="handleFileNameClick(row)"
            >
              <el-icon v-if="isPdfFile(row.fileType)" class="file-icon">
                <Document />
              </el-icon>
              {{ row.originalName }}
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="tags" label="标签" width="200">
          <template #default="{ row }">
            <div class="tags-container">
              <el-tag
                v-for="tag in row.tags"
                :key="tag"
                size="small"
                class="tag-item"
              >
                {{ tag }}
              </el-tag>
              <span v-if="!row.tags || row.tags.length === 0" class="no-tags">
                暂无标签
              </span>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="description" label="描述" min-width="300">
          <template #default="{ row }">
            <div class="description text-truncate" :title="row.description">
              {{ row.description || '暂无描述' }}
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag
              :type="getStatusType(row.status)"
              size="small"
            >
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="fileSize" label="文件大小" width="120">
          <template #default="{ row }">
            {{ formatFileSize(row.fileSize) }}
          </template>
        </el-table-column>
        
        <el-table-column prop="createTime" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.createTime) }}
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-dropdown v-if="isPdfFile(row.fileType)" @command="(command) => handlePdfAction(command, row)" trigger="click">
              <el-button type="primary" link size="small" @click.stop>
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
              link
              size="small"
              @click.stop="downloadFile(row)"
              :loading="downloadingIds.has(row.id)"
            >
              <el-icon><Download /></el-icon>
              下载
            </el-button>
            <el-button
              type="primary"
              link
              size="small"
              @click.stop="viewDetail(row.id)"
            >
              查看详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="queryParams.page"
          v-model:page-size="queryParams.size"
          :page-sizes="[10, 20, 50, 100]"
          :total="literatureStore.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 导入文献模态框 -->
    <ImportLiteratureModal
      v-model="showImportModal"
      @success="handleImportSuccess"
    />
    
    <!-- 批量导入文献模态框 -->
    <BatchImportModal
      v-model="showBatchImportModal"
      @success="handleBatchImportSuccess"
    />
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useLiteratureStore } from '@/stores/literatureStore'
import { ElMessage } from 'element-plus'
import ImportLiteratureModal from '@/components/ImportLiteratureModal.vue'
import BatchImportModal from '@/components/BatchImportModal.vue'
import { Plus, Search, Refresh, Download, Upload, Document, ArrowDown, View, FolderOpened } from '@element-plus/icons-vue'
import { ElMessageBox } from 'element-plus'

const router = useRouter()
const literatureStore = useLiteratureStore()

// 响应式数据
const showImportModal = ref(false)
const showBatchImportModal = ref(false)
const dateRange = ref([])
const downloadingIds = ref(new Set())

// 查询参数的本地副本
const queryParams = reactive({
  page: 1,
  size: 10,
  keyword: '',
  tags: [],
  fileType: '',
  startDate: '',
  endDate: ''
})

// 监听 store 中的查询参数变化，同步到本地（仅在初始化时）
watch(() => literatureStore.queryParams, (newParams) => {
  Object.assign(queryParams, newParams)
}, { deep: true, immediate: true })

// 处理搜索
const handleSearch = () => {
  queryParams.page = 1 // 重置到第一页
  literatureStore.updateQueryParams(queryParams)
  literatureStore.fetchLiteratures()
}

// 处理重置
const handleReset = () => {
  const resetParams = {
    page: 1,
    size: 10,
    keyword: '',
    tags: [],
    fileType: '',
    startDate: '',
    endDate: ''
  }
  Object.assign(queryParams, resetParams)
  dateRange.value = []
  literatureStore.updateQueryParams(resetParams)
  literatureStore.fetchLiteratures()
}

// 处理日期范围变化
const handleDateRangeChange = (dates) => {
  if (dates && dates.length === 2) {
    queryParams.startDate = dates[0]
    queryParams.endDate = dates[1]
  } else {
    queryParams.startDate = ''
    queryParams.endDate = ''
  }
}

// 处理页码变化
const handleCurrentChange = (page) => {
  queryParams.page = page
  literatureStore.updateQueryParams({ page })
  literatureStore.fetchLiteratures()
}

// 处理每页大小变化
const handleSizeChange = (size) => {
  queryParams.size = size
  queryParams.page = 1
  literatureStore.updateQueryParams({ size, page: 1 })
  literatureStore.fetchLiteratures()
}

// 处理表格行点击
const handleRowClick = (row) => {
  viewDetail(row.id)
}

// 判断是否为PDF文件
const isPdfFile = (fileType) => {
  return fileType && fileType.toLowerCase() === 'pdf'
}

// 处理文件名点击
const handleFileNameClick = (row) => {
  if (isPdfFile(row.fileType)) {
    // PDF文件直接预览
    previewPdfFile(row)
  } else {
    // 其他文件类型跳转到详情页
    viewDetail(row.id)
  }
}

// 预览PDF文件
const previewPdfFile = (literature) => {
  try {
    // 构建预览URL - 添加时间戳防止缓存，确保显示最新内容（包括标注高亮）
    const timestamp = new Date().getTime()
    const previewUrl = `/api/literature/${literature.id}/preview?t=${timestamp}`
    
    // 在新窗口中打开PDF预览
    const newWindow = window.open(previewUrl, '_blank', 'width=1200,height=800,scrollbars=yes,resizable=yes')
    
    if (!newWindow) {
      // 如果弹窗被阻止，提示用户
      ElMessage.warning('请允许弹窗以预览PDF文件，或者点击"查看详情"按钮')
    } else {
      // 设置新窗口标题
      newWindow.document.title = `预览 - ${literature.originalName}`
    }
  } catch (error) {
    console.error('预览PDF文件失败:', error)
    ElMessage.error('预览PDF文件失败，请重试')
  }
}

// 使用本地PDF阅读器打开
const openWithLocalReader = async (literature) => {
  try {
    // 获取文件本地路径
    const response = await fetch(`/api/literature/${literature.id}/local-path`)
    const result = await response.json()
    
    if (!result.success) {
      throw new Error(result.message || '获取文件路径失败')
    }
    
    const localPath = result.data
    
    // 检测操作系统并使用相应的方法打开文件
    const userAgent = navigator.userAgent.toLowerCase()
    
    if (userAgent.includes('win')) {
      // Windows系统
      await openFileOnWindows(localPath, literature.originalName)
    } else if (userAgent.includes('mac')) {
      // macOS系统
      await openFileOnMac(localPath, literature.originalName)
    } else {
      // Linux或其他系统
      await openFileOnLinux(localPath, literature.originalName)
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
const handlePdfAction = (command, literature) => {
  switch (command) {
    case 'preview':
      previewPdfFile(literature)
      break
    case 'openLocal':
      openWithLocalReader(literature)
      break
    case 'download':
      downloadFile(literature)
      break
  }
}

// 查看详情
const viewDetail = (id) => {
  router.push(`/literature/${id}`)
}

// 处理导入成功
const handleImportSuccess = () => {
  showImportModal.value = false
  // 刷新列表
  literatureStore.fetchLiteratures()
}

// 处理批量导入成功
const handleBatchImportSuccess = () => {
  showBatchImportModal.value = false
  // 刷新列表
  literatureStore.fetchLiteratures()
}

// 下载文件
const downloadFile = async (literature) => {
  if (!literature || downloadingIds.value.has(literature.id)) {
    return
  }

  try {
    // 添加到下载中的ID集合
    downloadingIds.value.add(literature.id)
    
    // 创建下载链接
    const downloadUrl = `/api/literature/${literature.id}/download`
    
    // 使用fetch检查文件是否存在
    const response = await fetch(downloadUrl, { method: 'HEAD' })
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    // 创建临时链接进行下载
    const link = document.createElement('a')
    link.href = downloadUrl
    link.download = literature.originalName || '文献文件'
    link.style.display = 'none'
    
    // 添加到页面并触发下载
    document.body.appendChild(link)
    link.click()
    
    // 清理
    document.body.removeChild(link)
    
    // 提示下载开始
    ElMessage.success(`${literature.originalName} 下载已开始`)
    
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
    // 从下载中的ID集合移除
    downloadingIds.value.delete(literature.id)
  }
}

// 格式化文件大小
const formatFileSize = (bytes) => {
  if (!bytes || bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 格式化日期时间
const formatDateTime = (dateTime) => {
  if (!dateTime) return '-'
  return new Date(dateTime).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 获取状态类型
const getStatusType = (status) => {
  const statusMap = {
    0: 'warning',
    1: 'success',
    2: 'danger'
  }
  return statusMap[status] || 'info'
}

// 获取状态文本
const getStatusText = (status) => {
  const statusMap = {
    0: '处理中',
    1: '已完成',
    2: '失败'
  }
  return statusMap[status] || '未知'
}

// 组件挂载时获取数据
onMounted(() => {
  literatureStore.fetchLiteratures()
})
</script>

<style scoped>
.literature-list-view {
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  gap: 24px;
}

.header-left {
  flex: 1;
}

.page-title {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #2c3e50;
  display: flex;
  align-items: baseline;
  gap: 16px;
}

.page-slogan {
  font-size: 14px;
  color: #606266;
  font-weight: 400;
  white-space: nowrap;
}

.import-buttons {
  display: flex;
  gap: 12px;
}

.filter-card {
  border: 1px solid #ebeef5;
}

.filter-form {
  margin: 0;
}

.filter-form .el-form-item {
  margin-bottom: 0;
}

.literature-table {
  margin-bottom: 16px;
}

.literature-table :deep(.el-table__row) {
  cursor: pointer;
}

.literature-table :deep(.el-table__row:hover) {
  background-color: #f5f7fa;
}

.file-name {
  font-weight: 500;
  color: #409eff;
  display: flex;
  align-items: center;
  gap: 6px;
}

.file-name.clickable {
  cursor: pointer;
  transition: all 0.2s ease;
}

.file-name.clickable:hover {
  color: #66b1ff;
  text-decoration: underline;
}

.file-icon {
  font-size: 14px;
  color: #f56c6c;
}

.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.tag-item {
  margin: 0;
}

.no-tags {
  color: #909399;
  font-size: 12px;
}

.description {
  max-width: 300px;
  line-height: 1.4;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 16px;
}

.mb-16 {
  margin-bottom: 16px;
}

.mb-24 {
  margin-bottom: 24px;
}

.text-truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
