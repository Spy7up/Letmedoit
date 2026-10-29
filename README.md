# 让我做（letmedoit）

> 帮手间的日常任务委托与提醒。别人让你做的小事，说一遍就够。

「让我做」是给熟人关系（家人、室友、情侣、帮手）用的**口头委托承接箱**：妈妈喊你晾衣服、室友让你带瓶酱油——说出口的那一刻就落成一条结构化任务，自动提醒相关的人，做完对方第一时间知道。

## 功能概述

- **任务委托**：布置任务给 1~10 个帮手，两种完成条件（任一人完成 / 全员完成），支持截止提醒与定时生效
- **每人一格**：参与者各自接受 / 拒绝 / 完成（附备注与凭证图），聚合状态由服务端统一计算
- **帮手关系**：分享邀请卡片或 6 位邀请码建立双向关系，无陌生人社交
- **站内通知**：与微信「服务通知」同构的消息中心，未读红点（仅站内信，无订阅消息推送）
- **我的**：头像昵称、统计、协议阅读、问题与反馈、注销账号、版本号（接口统一下发）
- **合规**：隐私授权弹窗、内容安全检测（文本 + 图片）、任务举报入口

## 技术栈

| 层 | 选型 |
|---|---|
| 前端 | 微信小程序原生 WXML/WXSS（基础库 ≥ 2.32.3），自定义悬浮液态玻璃 tabBar |
| 后端 | SpringBoot 3.5.4 / Java 17，基于 SmartAdmin 3.x 多模块（sa-base / sa-app / sa-admin） |
| 鉴权 | Sa-Token 双体系隔离：后台 `Authorization` + 小程序 `App-Token` |
| 存储 | MySQL 8 + Redis / Redisson（缓存、分布式锁、定时作业互斥） |
| 对象存储 | 腾讯云 COS（S3 兼容，图片公网可读） |
| 定时任务 | `t_smart_job` + Redisson 锁（预约生效、到期提醒） |

## 目录结构

```
letmedoit/
├── letmedoit-miniprogram/   # 微信小程序前端（原生 WXML/WXSS）
├── letmedoit-api/           # 后端服务（SpringBoot：sa-base / sa-app / sa-admin）
├── doc/                     # 设计文档与高保真原型（归档）
│   ├── design/              # 总设计文档
│   └── prototype/           # 按功能模块拆分的原型，浏览器打开 index.html
└── xhs-launch/              # 小红书上线物料
```

## 文档导航

| 我要… | 看这里 |
|---|---|
| 了解产品设计全貌 | [`doc/design/让我做-总设计文档.md`](./doc/design/让我做-总设计文档.md) |
| 看高保真原型 | [`doc/prototype/index.html`](./doc/prototype/index.html) |
| 开发小程序端 | [`letmedoit-miniprogram/README.md`](./letmedoit-miniprogram/README.md) + `docs/AI-Agent-小程序开发规范.md` |
| 开发后端 | [`letmedoit-api/README.md`](./letmedoit-api/README.md) + `docs/AI-Agent-后端开发规范.md` |
| 改数据库 | [`letmedoit-api/docs/sql/README.md`](./letmedoit-api/docs/sql/README.md)（改库前必读） |
| 部署上线 | [`letmedoit-api/deploy/DOCKER-DEPLOY.md`](./letmedoit-api/deploy/DOCKER-DEPLOY.md) |

## Git 约定

- 一次提交尽量只落在同一边：前端 `letmedoit-miniprogram/`、后端 `letmedoit-api/`，提交信息用 `feat(miniprogram):` / `feat(api):` 前缀区分。
- 两端各有一套 `.gitignore`；`.workbuddy/` 为本地工作目录，不纳入版本管理。
- 配置文件禁止明文密钥：一律 `${ENV:默认值}` 占位，敏感项默认值留空（见 `letmedoit-api/docs/CONFIG_SECRETS.md`）。
