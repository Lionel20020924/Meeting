# 火山引擎 ASR 配置说明

## 当前问题

ASR API 返回错误：`"app key not found in header or query"`

## 原因分析

当前环境变量配置可能不完整。火山引擎语音识别服务通常需要以下认证信息：

1. **App ID** - 应用ID（数字格式）
2. **App Key** - 应用密钥（长字符串格式，通常32-64位）
3. **Access Key** - 访问密钥
4. **Secret Key** - 秘密密钥（用于签名）

## 当前配置

```env
VOLCANO_APP_KEY=1864831691  # 这看起来是 App ID，不是 App Key
VOLCANO_ACCESS_KEY=og6aTdx_f3sA2Inbd0PHaLcgwgdmhCl3
```

## 解决方案

### 1. 登录火山引擎控制台

访问 [火山引擎控制台](https://console.volcengine.com/)

### 2. 查找语音识别服务

1. 进入"语音技术" > "语音识别"
2. 找到您的应用配置

### 3. 获取完整的认证信息

您应该能看到类似这样的信息：
- **应用ID (App ID)**: 1864831691
- **应用密钥 (App Key)**: 一个长字符串，如 `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`
- **Access Key ID**: 用于API访问
- **Secret Access Key**: 用于签名

### 4. 更新环境变量

将 `.env` 文件更新为：

```env
# 火山引擎 API 配置
VOLCANO_APP_ID=1864831691  # 应用ID
VOLCANO_APP_KEY=<从控制台获取的真正的App Key>  # 应用密钥
VOLCANO_ACCESS_KEY=og6aTdx_f3sA2Inbd0PHaLcgwgdmhCl3
```

### 5. 验证配置

确保您已经：
1. 开通了语音识别服务
2. 创建了应用
3. 获取了正确的 App Key（不是 App ID）

## API 调用格式

火山引擎 ASR v3 API 期望在查询参数或请求头中包含 `app_key`：

```
https://openspeech.bytedance.com/api/v3/auc/bigmodel/submit?app_key=<your_app_key>
```

或在请求头中：
```
X-App-Key: <your_app_key>
```

## 注意事项

- App ID 和 App Key 是两个不同的值
- App Key 通常是一个较长的随机字符串
- 不要将 App ID 当作 App Key 使用