# 火山引擎语音识别服务集成

本模块实现了火山引擎语音识别（ASR）大模型服务的集成，用于替代 OpenAI Whisper 进行语音转文字。

**重要更新**：
- 使用最新的 v3 大模型 API
- TOS 服务使用 MinIO 客户端（S3 兼容）
- 集成豆包 AI 生成会议摘要

## 功能特点

- 支持中文语音识别，效果优秀
- 国内服务，延迟更低
- 支持多种音频格式（MP3、WAV、M4A、AAC 等）
- 支持时间戳和标点符号
- 支持说话人分离（diarization）
- 支持智能分段
- 集成豆包 AI 自动生成会议摘要

## 配置步骤

### 1. 获取 API 密钥

1. 访问[火山引擎控制台](https://console.volcengine.com/)
2. 创建应用并获取：
   - App Key
   - Access Key
3. 开通对象存储（TOS）服务并获取：
   - Access Key ID
   - Secret Access Key
   - 创建存储桶（Bucket）

### 2. 配置环境变量

在项目根目录的 `.env` 文件中添加：

```env
# 火山引擎 API 配置
VOLCANO_APP_KEY=your_app_key
VOLCANO_ACCESS_KEY=your_access_key

# TOS 对象存储配置
TOS_ACCESS_KEY_ID=your_tos_access_key_id
TOS_SECRET_ACCESS_KEY=your_tos_secret_access_key
TOS_ENDPOINT=tos-s3-cn-beijing.volces.com
TOS_BUCKET_NAME=your_bucket_name
TOS_REGION=cn-beijing

# 豆包 AI 配置（可选，用于生成会议摘要）
ARK_API_KEY=your_doubao_ai_api_key
```

**注意**：
- TOS_SECRET_ACCESS_KEY 如果是 Base64 编码的，系统会自动解码
- 确保 TOS_REGION 拼写正确（是 `cn-beijing` 而不是 `cn-beijin`）
- ARK_API_KEY 用于调用豆包 AI 生成会议摘要

### 3. 使用方式

系统会自动检测可用的转录服务，优先使用火山引擎：

```dart
// 自动选择最佳服务
final result = await TranscriptionService.transcribeAudio(
  audioData: audioBytes,
  language: 'zh',
);

// 强制使用火山引擎
final result = await TranscriptionService.transcribeAudio(
  audioData: audioBytes,
  language: 'zh',
  provider: TranscriptionProvider.volcano,
);
```

## 服务优先级

1. **火山引擎** - 优先使用（如果配置可用）
2. **WhisperX** - 第二选择
3. **OpenAI** - 最后备选

## 注意事项

1. **存储桶权限**：确保 TOS 存储桶有适当的读写权限
2. **音频格式**：建议使用 M4A 或 WAV 格式以获得最佳效果
3. **文件大小**：单个音频文件建议不超过 500MB
4. **并发限制**：注意 API 的并发请求限制

## 错误处理

服务会自动进行错误处理和降级：
- 如果火山引擎服务不可用，会自动切换到 WhisperX 或 OpenAI
- 网络错误会自动重试
- 所有错误都会记录在日志中

## 成本优化

- 音频文件会自动上传到 TOS，转录完成后可以选择删除
- 建议定期清理 TOS 中的历史文件
- 可以通过配置控制音频质量来平衡成本和效果