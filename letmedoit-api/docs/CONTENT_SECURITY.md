# 内容安全接入说明（提审必看）

> 小程序审核硬性要求：**所有用户输入（UGC 文本）与用户上传的图片都必须经过微信内容安全检测**，
> 没有接入的一律驳回。本文说明本项目接了什么、怎么配、怎么验证、怎么排查。

---

## 1. 覆盖范围

### 1.1 文本 —— 同步拦截（`msgSecCheck` v2）

命中风险直接拒绝提交，接口返回业务错误，前端 toast 显示后端文案。

| 输入点 | 字段 | scene | 位置 |
| --- | --- | --- | --- |
| 布置任务 · 标题 | `title` | 4 社交日志 | `TaskService.create` |
| 布置任务 · 交代内容 | `description` | 4 | `TaskService.create` |
| 编辑任务 · 标题/内容 | `title`/`description` | 4 | `TaskService.update` |
| 完成任务的备注 | `remark` | 4 | `TaskService.complete` |
| 拒绝任务的理由 | `reason` | 4 | `TaskService.reject` |
| 帮手申请附言 | `applyMessage` | 4 | `HelperService.apply` |
| 昵称（资料页修改） | `nickname` | 1 资料 | `WxAuthService.updateProfile` |
| 昵称（登录时带上） | `nickname` | 1 资料 | `WxAuthService.login` |

### 1.2 图片 —— 异步检测 + 违规下架（`mediaCheckAsync` v2）

图片走的是「先放行、后追责」：上传时拿到 `trace_id` 落库，微信在 **30 分钟内**把结论推送到
消息接收服务器，判定违规后自动下架。

| 输入点 | biz_type | 触发位置 | 违规后的动作 |
| --- | --- | --- | --- |
| 头像 | `avatar` | `AppFileService.uploadImage`（bizType=avatar） | 头像置空，回落到「昵称末字 + 色块」默认头像 |
| 任务附图 | `task_image` | `AppFileService.uploadImage` | 从 `t_task.images` 剔除 + 通知委托人 |
| 完成凭证图 | `task_proof` | 同上（路径相同，下架时两张表都清） | 从 `t_task_participant.complete_images` 剔除 + 通知委托人 |

> **唯一上传入口就是 `/api/file/upload`**，所以图片检测只接了一处 ——
> 任务附图、凭证图、头像全走它，不存在漏网的图片。

---

## 2. 微信后台怎么配（4 步）

1. 打开 **微信公众平台 → 开发管理 → 开发设置 → 消息推送**，点「启用」。
2. 填三个值：

   | 项 | 值 |
   | --- | --- |
   | URL(服务器地址) | `https://你的域名/api/wx/push` |
   | Token(令牌) | 自己定一串随机字符，与后端 `WX_PUSH_TOKEN` **完全一致** |
   | EncodingAESKey | 不用填（明文模式下不需要） |
   | 消息加解密方式 | **明文模式** |
   | 数据格式 | **JSON**（不是 XML） |

3. 后端注入环境变量（与上面 Token 一致）：

   ```bash
   WX_PUSH_TOKEN=你刚才填的那串
   ```

4. 点「提交」，微信会立刻 GET 请求 `/api/wx/push?signature=...&echostr=...` 做连通性校验。
   后端验签通过会原样回 `echostr`，页面提示「保存成功」即打通。

> 配好后回到 **开发管理 → 接口设置**，确认 `security.msgSecCheck` 与
> `security.mediaCheckAsync` 都是「已获得」。

### 注意

- 消息推送**必须走 HTTPS 且 80/443 端口**，微信不接受自定义端口号但接受 443 上的任意路径。
- 后端验签失败会返回 `invalid signature`，微信侧保存配置就会失败 —— 九成是 Token 不一致。
- 推送接口已加到拦截器白名单（`AppMvcConfig.WX_PUSH_PATH`），**不需要登录态**，
  身份完全由签名保证。别把它从白名单里删掉，删了推送全 401。

---

## 3. 配置项

```yaml
wx:
  miniapp:
    content-check:
      enabled: true                  # 生产必须 true，关掉等于没接
      fail-open: true                # 微信接口抖动时是否放行（默认放行，不阻塞用户）
      push-token: ${WX_PUSH_TOKEN:}  # 与微信后台消息推送的 Token 一致
      text-scene: 4                  # 1资料 2评论 3论坛 4社交日志
      image-scene: 4
      avatar-scene: 1
      pending-timeout-minutes: 35    # 异步结果超时阈值
```

**`fail-open` 怎么选**：

- `true`（默认）：微信接口挂了/超时，用户照样能发任务，代价是这段时间的内容没被检测。
- `false`：检测不通就不许提交，最严，但微信侧一抖动全站不能发任务。

审核期间建议 `true`（可用性优先），有实锤违规风险再切 `false`。

---

## 4. 数据落库与排查

每次调用都落一条 `t_content_check`：

```sql
-- 最近 20 条检测记录
SELECT check_id, biz_type, status, suggest, label, left(content_brief, 30) AS brief,
       media_url, trace_id, create_time
FROM t_content_check ORDER BY check_id DESC LIMIT 20;

-- 违规记录（需要人工复核/申诉时看）
SELECT * FROM t_content_check WHERE status = 2 ORDER BY check_id DESC;

-- 长期挂在「审核中」的（说明推送没通）
SELECT COUNT(*) FROM t_content_check WHERE status = 0 AND create_time < NOW() - INTERVAL 35 MINUTE;
```

状态含义：`0 审核中 / 1 通过 / 2 违规（已下架）/ 3 检测失败`。

标签含义：`100 正常 / 20001 时政 / 20002 色情 / 20006 违法犯罪 / 21000 其他`。

`status=0` 长期不清零，基本就是这三种原因：

1. `WX_PUSH_TOKEN` 没配或与微信后台不一致 → 验签失败，推送全被拒；
2. 服务器地址不可达（HTTPS/域名/防火墙）；
3. 数据格式选了 XML（本项目按 JSON 解析）。

### 4.1 验签失败怎么定位（`invalid signature` / 日志「微信消息推送验签失败」）

后端现在会把「本地按当前 Token 算出的签名」一起打出来，直接对照：

```
WARN ... 微信消息推送验签失败：Token 不一致。收到 signature=abc..., 当前 Token(长度 22) 算出=def..., timestamp=..., nonce=...
```

- 日志出现 **「push-token 为空」** → 服务器没注入 `WX_PUSH_TOKEN`，去 `.env` 加一行再重启容器。
- 日志出现 **「Token 不一致」** → 两边 Token 不同。拿微信后台的 Token 跑一下自检脚本：

  ```bash
  node deploy/wx-push-sign.js <微信后台的 Token> <timestamp> <nonce> <日志里的 signature>
  ```

  输出「✅ 一致」说明 Token 没填错，问题在服务器没生效（没注入 / 没重启）；
  输出「❌ 不一致」说明微信后台填的和你以为的不是同一个。

> **最容易踩的坑**：`deploy/.env.prod.example` 早期版本没有 `WX_PUSH_TOKEN` 这一项，
> 照着模板配下来就是空的，本地 dev 能通、一上服务器就恒失败。现已补上。

---

## 5. 提审要准备什么

微信要求提交「接口调用成功的录屏」，按这个顺序录：

1. 小程序里发一条任务，标题写正常内容 → 发送成功；
2. 再发一条，标题写明显违规内容 → **被拦下并提示「任务标题含有不适合发布的内容」**；
3. 上传一张正常图片 → 成功；
4. 后台查 `t_content_check`，展示 `msgSecCheck` 与 `mediaCheckAsync` 两条真实调用记录
   （`suggest=pass` / `trace_id` 非空）。

> 录屏必须是真的调了微信接口，mock 模式（`wx.miniapp.mock=true`）不会真调，
> 录出来的记录 `trace_id` 是 `mock_` 开头，审核不认。

---

## 6. 代码位置

```
sa-app/src/main/java/net/lab1024/sa/app/
├── module/wx/WxApiService.java                     # msgSecCheck / mediaCheckAsync 封装
├── module/security/
│   ├── controller/WxMessagePushController.java     # 推送入口（验签 + wxa_media_check）
│   ├── service/ContentSecurityService.java         # 文本拦截 / 图片送检 / 结果处理 / 超时兜底
│   ├── service/ContentTakedownService.java         # 违规下架（图片从业务表剔除）
│   ├── constant/ContentCheckStatusEnum.java
│   ├── constant/ContentBizTypeEnum.java
│   ├── domain/entity/ContentCheckEntity.java
│   └── dao/ContentCheckDao.java
└── config/WxProperties.java                        # content-check 配置项
```

建表脚本：`docs/sql/init/letmedoit_init.sql`（`t_content_check`，全量里已包含；规则见 `docs/sql/README.md`）。
