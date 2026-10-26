# 用户协议与隐私政策接入说明

> 审核要求：小程序必须提供《用户协议》与《隐私政策》，且**用户同意后才能使用**。
> 本项目把协议正文放在数据库里，运营者改内容不用发版小程序。

---

## 1. 已实现的约束

| 约束 | 落点 |
| --- | --- |
| 登录页必须勾选同意 | `pages/launch/index` 勾选框，未勾选点登录直接拦截 |
| 后端二次校验（防绕过） | `WxAuthService.login`：`agreementVersion` 为空 → 拒绝 |
| 版本过期校验 | 用户同意过的版本 ≠ 当前生效版本 → 拒绝并提示重新阅读 |
| 同意留痕 | `t_app_agreement_record`：member + 类型 + 版本 + 时间 + IP + UA |
| 正文可后台改 | 正文存 `t_app_agreement.content`，读完即生效 |
| 协议接口免登录 | `/api/agreement/current`、`/api/agreement/detail` 在白名单里 |

> 前端勾选框只是提示，真正的闸门在 `WxAuthService.login`。审核看到的是"必须先同意才能用"，
> 而不是"界面上有个勾但能绕过"。

---

## 2. ⚠️ 上线前必须替换的占位符

协议正文里有两个占位符，**两处都必须**改成真实信息，否则不具备法律效力、审核也可能追问。

### 2.1 两种主体怎么填

| 占位符 | 公司主体 | 个人主体 |
| --- | --- | --- |
| `〔运营主体全称〕` | 营业执照上的**企业全称**，如"深圳市某某科技有限公司" | **本人真实姓名**，如"张三"（与微信小程序主体认证的身份证姓名一致） |
| `〔联系邮箱〕` | 公司客服邮箱，如 `support@example.com` | 本人常用邮箱，如 `zhangsan@qq.com` |

**个人主体三个不要写**：

1. **不要写"XX 工作室""XX 小店"** —— 未经工商登记的工作室不具备民事主体资格，写了等于没写主体，出纠纷时用户告不到人，审核也会以"主体信息不实"追问。
2. **不要写"个人开发者""个人""独立开发者"** —— 这是身份描述不是名称，协议里必须落到具体自然人。
3. **不要写别人的公司名** —— 冒用企业名义涉嫌虚假宣传，责任比不写还重。

> 个人主体的名字必须与**微信公众平台「设置 - 基本设置 - 主体信息」里的姓名完全一致**，
> 否则审核对比时会对不上。改过主体名称的记得同步改协议。

### 2.2 个人主体的三条硬限制

填姓名只是第一步，个人主体还有几个绕不过去的限制，会直接影响这个产品能做到什么程度：

1. **不能从事经营性服务**。个人主体小程序只允许做非盈利的信息服务。本项目是熟人之间的免费派活工具，符合要求；
   一旦加上收费、抽成、会员付费，就属于经营性服务，个人主体会被驳回或上线后下架。
2. **开不了微信支付**。微信支付只对企业和个体工商户开放，个人主体没有商户号。将来若要收费，必须先转成个体工商户/企业主体，
   届时协议里的运营者名称、主体信息都要跟着改。
3. **承担无限责任**。个人主体以个人全部财产对服务承担责任，公司主体以注册资本为限。协议里的免责条款能挡一部分，
   但内容安全（用户发违规内容）这块仍是实打实的风险 —— 这也是本项目必须接入内容安全检测的原因之一。

### 2.3 关于争议解决条款

原文已按主体无关的措辞写：

> 任何一方均可向**运营者住所地**有管辖权的人民法院提起诉讼。

个人主体不用改（"住所地"就是你的户籍地或经常居住地）；公司主体也不用改（就是注册地）。
如果你希望更明确，可以写成具体城市，例如"向杭州市有管辖权的人民法院提起诉讼"。

### 2.4 替换命令

```sql
-- 公司示例
UPDATE t_app_agreement
SET content = REPLACE(content, '〔运营主体全称〕', '深圳市某某科技有限公司'),
    update_time = NOW()
WHERE type IN ('user', 'privacy');

UPDATE t_app_agreement
SET content = REPLACE(content, '〔联系邮箱〕', 'support@example.com'),
    update_time = NOW()
WHERE type IN ('user', 'privacy');
```

```sql
-- 个人示例
UPDATE t_app_agreement
SET content = REPLACE(content, '〔运营主体全称〕', '张三'),
    update_time = NOW()
WHERE type IN ('user', 'privacy');

UPDATE t_app_agreement
SET content = REPLACE(content, '〔联系邮箱〕', 'zhangsan@qq.com'),
    update_time = NOW()
WHERE type IN ('user', 'privacy');
```

改完打个接口确认没有残留：

```sql
SELECT type, (content LIKE '%〔%') AS still_has_placeholder FROM t_app_agreement;
-- 两行都应该是 0
```

> 只改内容不升版本是对的：这属于补全主体信息，不是实质性变更，用户不需要重新同意。

---

## 3. 怎么改协议内容

### 3.1 小改（措辞、联系方式）—— 不升版本

```sql
UPDATE t_app_agreement
SET content = '新的正文……', update_time = NOW()
WHERE type = 'user' AND enabled_flag = 1;
```

用户下次打开就是新内容。**已经同意过的用户不会被要求重新同意**（版本没变）。

### 3.2 实质性变更（收集范围、用途、共享对象）—— 必须升版本

法律上这类变更必须重新取得同意，所以要发新版本：

```sql
-- 1) 先把旧版停用（保留历史，便于举证时回溯"当时用户同意的是哪一版"）
UPDATE t_app_agreement
SET enabled_flag = 0, update_time = NOW()
WHERE type = 'user' AND version = '1.0.0';

-- 2) 插入新版本
INSERT INTO t_app_agreement (type, title, version, content, effective_time, enabled_flag, create_time, update_time)
VALUES ('user', '用户协议', '1.0.1', '新正文……', NOW(), 1, NOW(), NOW());
```

> 两篇协议（user / privacy）任一篇升版，组合版本号都会变，
> 用户下次登录就会被要求重新阅读并同意 —— 这是预期行为，别改。

**别直接改已停用版本的 content**：那是用户当时同意的原文，改了举证就失真了。

### 3.3 改完怎么验证

```bash
# 看当前生效版本（组合号形如 u1.0.1|p1.0.0）
curl https://你的域名/api/agreement/current

# 正文
curl "https://你的域名/api/agreement/detail?type=privacy"
```

---

## 4. 查同意记录（举证用）

```sql
-- 某个用户同意过什么
SELECT agreement_type, version, agree_time, ip, user_agent
FROM t_app_agreement_record
WHERE member_id = 123
ORDER BY agree_time DESC;

-- 有多少人同意过当前版本
SELECT agreement_type, version, COUNT(*) AS cnt
FROM t_app_agreement_record
GROUP BY agreement_type, version
ORDER BY version DESC, agreement_type;
```

---

## 5. 与微信平台「用户隐私保护指引」的关系

两边都要配，作用不同：

| 位置 | 作用 | 谁来填 |
| --- | --- | --- |
| 微信后台「设置 - 服务内容声明 - 用户隐私保护指引」 | 平台级声明，审核必查，不填会被驳回 | 小程序管理员在后台手工填写 |
| 本项目 `t_app_agreement` 的《隐私政策》 | 用户可读的完整法律文本，登录时强制同意 | 运营者维护（本文第 2、3 节） |

**两处内容必须一致**（收集了哪些信息、用途、第三方共享），否则审核会以"告知不一致"驳回。

本项目实际收集的信息清单见《隐私政策》第 1 节，填写微信后台时逐条对应即可。

---

## 6. 代码位置

```
sa-app/src/main/java/net/lab1024/sa/app/
├── module/agreement/
│   ├── controller/AppAgreementController.java   # current / detail / agree
│   ├── service/AppAgreementService.java         # 取生效版本、留痕、启动自检
│   ├── dao/AppAgreementDao.java
│   ├── dao/AppAgreementRecordDao.java
│   ├── domain/entity/AppAgreementEntity.java
│   └── domain/entity/AppAgreementRecordEntity.java
└── module/member/service/WxAuthService.java     # 登录处强制校验 agreementVersion

miniprogram/
├── pages/agreement/index.*                      # 协议阅读页（正文从后端取）
├── pages/launch/index.*                         # 登录页勾选
└── services/agreement.js                        # 协议接口 + 正文解析
```

建表与初始正文：`docs/sql/letmedoit_agreement.sql`
正文源文件（改完记得同步进库）：`docs/legal/user-agreement.md`、`docs/legal/privacy-policy.md`

---

## 7. 审核前自查清单

- [ ] `〔运营主体全称〕`、`〔联系邮箱〕` 已替换为真实信息
- [ ] 微信后台「用户隐私保护指引」已填写并生效，内容与本项目《隐私政策》一致
- [ ] 登录页未勾选协议时点登录，确实被拦下（真机验证）
- [ ] 协议页能正常打开、能滚到底（正文较长）
- [ ] `t_app_agreement_record` 有真实同意记录（说明链路通了）
- [ ] 隐私政策里列出的信息，与代码实际收集的一致（新增字段时记得回来补）
