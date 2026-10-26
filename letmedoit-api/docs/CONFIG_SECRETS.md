# 后端敏感配置说明

> 从 2026-10-26 起，`letmedoit-api` 的配置文件（`sa-base.yaml` / `application.yaml`）**不再包含任何明文凭证**。
> 数据库账号密码、Redis 密码、邮箱授权码、COS 密钥、微信 AppSecret 全部改为环境变量注入，未设置时为空默认值。

---

## 1. 环境变量清单

### 数据库

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `DB_HOST` | MySQL 主机 | `127.0.0.1` |
| `DB_PORT` | MySQL 端口 | `3306` |
| `DB_NAME` | 库名 | dev/test/pre: `smart_admin_v3`；prod: `letmedoit` |
| `DB_USERNAME` | 数据库账号 | 空 |
| `DB_PASSWORD` | 数据库密码 | 空 |
| `DRUID_USERNAME` | Druid 监控页账号（`login.enabled: false`，一般不用） | `druid` |
| `DRUID_PASSWORD` | Druid 监控页密码 | 空 |

### Redis

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `REDIS_HOST` | Redis 主机 | `127.0.0.1` |
| `REDIS_PORT` | Redis 端口 | `6379` |
| `REDIS_PASSWORD` | Redis 密码（无密码留空） | 空 |

### 邮件（找回归密码 / 通知）

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `MAIL_USERNAME` | 发件邮箱账号 | 空 |
| `MAIL_PASSWORD` | 邮箱 SMTP 授权码 | 空 |

### 对象存储（腾讯云 COS）

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `COS_SECRET_ID` | SecretId | 空（**cloud 模式缺失会启动失败**） |
| `COS_SECRET_KEY` | SecretKey | 空（**cloud 模式缺失会启动失败**） |
| `COS_REGION` | 地域 | `ap-guangzhou` |
| `COS_ENDPOINT` | Endpoint | `https://cos.ap-guangzhou.myqcloud.com` |
| `COS_BUCKET` | 桶名（含 APPID 后缀） | `letmedoit-1308200923` |
| `COS_DOMAIN` | 公有读访问域名（公开信息） | 桶对应域名 |
| `FILE_STORAGE_MODE` | `cloud` / `local` | `cloud` |

> 本地不想配 COS 凭证时：`FILE_STORAGE_MODE=local`，图片存本地磁盘。

### 微信小程序

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `WX_MINIAPP_APPID` | 小程序 AppID | 空 |
| `WX_MINIAPP_SECRET` | 小程序 AppSecret | 空 |

> `WX_MINIAPP_APPID` 为空时，`mock: false` 的登录链路会失败——本地纯接口联调可临时把对应 profile 的 `wx.miniapp.mock` 改为 `true`。

### 接口文档 Basic 认证（当前 `enable: false`）

| 变量 | 说明 |
| --- | --- |
| `KNIFE4J_USERNAME` | 用户名 |
| `KNIFE4J_PASSWORD` | 密码 |

---

## 2. 本地如何注入

推荐把值写进 `letmedoit-api/.env`（已在 `.gitignore`，不会提交），启动前加载。模板见同目录 `.env.example`。

### Git Bash / macOS / Linux

```bash
cp .env.example .env      # 首次：填入真实值
set -a; source .env; set +a
java -jar sa-app/target/sa-app-dev-3.0.0.jar --server.port=1025
```

### Windows CMD

```bat
for /f "usebackq tokens=1,* delims==" %i in (".env") do set "%i=%j"
java -jar sa-app\target\sa-app-dev-3.0.0.jar --server.port=1025
```

### IDEA

`Run/Debug Configurations` → `Environment variables` → 粘贴 `.env` 内容（IDEA 支持 `KEY=VALUE;KEY2=VALUE2` 格式，或装 EnvFile 插件直接指向 `.env`）。

### 服务器 / Docker

Docker Compose 用 `env_file: .env`；systemd 用 `EnvironmentFile=/opt/letmedoit/.env`。
生产环境请用密钥管理服务（如 KMS / Secret Manager）注入，不要明文落盘。

---

## 3. 必须知道的遗留风险

**本次只做了「当前文件脱敏」，没有改写 git 历史。**

- GitHub 上的历史提交（共 13 个 commit）中，`sa-base.yaml` 与 `sa-app/application.yaml` 的旧版本**仍然包含全部明文凭证**，任何人拿到仓库都能翻出来。
- 因此，以下凭证**必须视为已泄露并立即轮换**：
  1. MySQL 账号密码（`saAdmin` / `letmedoitadmin`，dev/pre/prod 三套）
  2. Redis 密码
  3. 腾讯云 COS 的 SecretId / SecretKey —— **优先级最高**，可直接被用来读写整桶
  4. 163 邮箱 SMTP 授权码
  5. 微信小程序 AppSecret —— 到微信公众平台「开发管理 → 开发设置」重置，重置后同步更新所有部署环境的环境变量
- 轮换后，GitHub 上的旧值即失效。若还想彻底清除痕迹，需要改写历史（`git filter-repo` 重写 + force push + 联系 GitHub 清理缓存），届时再评估。

### 以后提交前自检

```bash
# 应无输出
git diff --cached | grep -E "password|secret|access-key|AKID|ur9oh7|virtwuu"
```
