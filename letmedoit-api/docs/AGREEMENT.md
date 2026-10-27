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

## 2. 运营者信息怎么写（本项目用「本小程序作者」）

协议正文**不写真实姓名、不写邮箱**，统一用代称：

| 位置 | 正文里写的是 |
| --- | --- |
| 运营者 | 本小程序作者 |
| 联系方式 | 小程序内「我的 → 问题与反馈」 |
| 正文主体 | 本小程序作者（以下简称"我们"） |
| 争议解决 | 向**有管辖权的人民法院**提起诉讼（不写住所地） |

三个理由：

1. 正文里出现个人真实姓名、邮箱，等于把个人信息又公开一遍，没必要；
2. 联系渠道用小程序内的「问题与反馈」（后台有记录、可追溯）比邮箱更可达；
3. 不写"个人开发者""XX 工作室"这类**不是民事主体**的表述 —— 工作室未登记不具备主体资格，身份描述则等于没写。

### 2.1 和微信后台主体信息的关系

两边不是一回事，别混：

| 位置 | 填什么 | 谁维护 |
| --- | --- | --- |
| 微信公众平台「设置 - 基本设置 - 主体信息」 | **必须真实**：个人主体就是身份证姓名，企业就是营业执照全称 | 管理员在后台填，改不了 |
| 本项目的协议正文（`t_app_agreement.content`） | 用「本小程序作者」指代，不暴露姓名 | 运营者维护 |

审核如果追问"运营者是谁"，回答：与小程序的认证主体一致，正文以作者指代。**不要冒用公司名义**，也不要把"个人开发者"当成主体名称写进协议。

### 2.2 已经上线了怎么改（不升版本）

正文在数据库里，改库才生效；源文件 `docs/legal/user-agreement.md`、`privacy-policy.md` 同步改，两边保持一致。

这类改动属于**措辞与联系方式调整**，不升版本，已同意过的用户不会被要求重新同意：

```sql
-- 建议用脚本按 md 文件整段写入：content 里带换行和引号，手工拼 SQL 容易出错
UPDATE t_app_agreement
SET content = '<新的完整正文>', update_time = NOW()
WHERE type = 'user' AND enabled_flag = 1;
```

改完验一遍，两行都不该有残留：

```sql
SELECT type,
       (content LIKE '%〔%')  AS has_placeholder,
       (content LIKE '%@%')   AS has_email,
       (content LIKE '%住所地%') AS has_domicile
FROM t_app_agreement
WHERE enabled_flag = 1;
```

> 如果哪天真的改成"指定城市管辖"，那就属于条款实质变更，需要升版本并重新取得同意（见第 3.2 节）。

### 2.3 将来换成公司主体怎么办

只有升级为企业/个体工商户时才需要动正文：把「本小程序作者」整体替换成营业执照上的**企业全称**，
联系方式可保留「问题与反馈」或改成客服邮箱。这种变更建议**升版本**（主体变了，属于实质性变更），
同时同步微信后台的主体信息与「用户隐私保护指引」。

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

建表与初始正文：`docs/sql/init/letmedoit_init.sql`（表结构 + 「五、初始数据」第 11 项）
规则见 `docs/sql/README.md`
正文源文件（改完记得同步进库）：`docs/legal/user-agreement.md`、`docs/legal/privacy-policy.md`

---

## 7. 审核前自查清单

- [ ] 正文里没有 `〔` 占位符、没有邮箱、没有「住所地」，运营者写的是「本小程序作者」
- [ ] 微信后台「用户隐私保护指引」已填写并生效，内容与本项目《隐私政策》一致
- [ ] 登录页未勾选协议时点登录，确实被拦下（真机验证）
- [ ] 协议页能正常打开、能滚到底（正文较长）
- [ ] `t_app_agreement_record` 有真实同意记录（说明链路通了）
- [ ] 隐私政策里列出的信息，与代码实际收集的一致（新增字段时记得回来补）
