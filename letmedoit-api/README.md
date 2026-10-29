# letmedoit-api · 后端

「让我做」后端服务（SpringBoot 3.5.4 / Java 17），基于 SmartAdmin 3.x 多模块骨架。项目整体介绍见[根目录 README](../README.md)，业务与接口设计见 [`doc/design/让我做-总设计文档.md`](../doc/design/让我做-总设计文档.md)。

## 开发现状

- **sa-app**（小程序 C 端，本项目主战场）：微信登录、会员资料与注销、帮手、任务全状态机（含 `TaskScheduleJob` 定时作业）、站内通知、问题与反馈、版本下发、文件上传（COS）、内容安全，已全部联调上线。
- **sa-base**：框架底座（Web / MyBatis-Plus / Redis / sa-token / 文件存储 / 定时任务等 20+ support 能力）。
- **sa-admin**：管理后台，本期只有框架能力，无业务页面（反馈处理、版本发布界面待做）。

```bash
# 编译（先停掉正在运行的 java 进程，否则 Windows 锁 jar 导致 repackage 静默失败）
mvn -o -pl sa-app -am package -DskipTests -Pdev     # PATH 无 mvn 时用 ~/.m2/wrapper 里的

# 启动（必须显式指定端口，否则被宿主 SERVER__PORT 覆盖）
java -jar sa-app/target/sa-app-dev-3.0.0.jar --server.port=1025
```

Swagger：`http://localhost:1025/doc.html`。生产部署见 [`deploy/DOCKER-DEPLOY.md`](./deploy/DOCKER-DEPLOY.md)。

## 开发注意事项

- **改数据库前必读 [`docs/sql/README.md`](./docs/sql/README.md)**：全仓只有一个初始化脚本 `docs/sql/init/letmedoit_init.sql`（新库只跑它）；已有库的每次变更以**当天日期**新建 `docs/sql/updates/<日期>/` 文件夹存放增量脚本（幂等、按序号执行），并同步 init + 写日期目录 README。已发布的 updates 不许再改。
- **给 `t_task` 加列必须同步 `TaskMapper.xml` 的 `<sql id="baseColumns">`**，否则「INSERT 成功但 queryById 查不出来」。
- **通知表是 `t_task_notice`**，不是 `t_notice`（框架自带公告表，撞名会写错表）。
- **状态流转**一律 `UPDATE ... WHERE status = 旧值`；聚合状态与 `canXxx` 权限位只由服务端 `TaskManager` 算。
- **新模块取名前先 grep sa-base**：`module/support/` 下有同名类会让应用启动失败；本项目统一 `App*` 前缀、`@Resource` 字段名也带 `app` 前缀。
- **配置禁止明文密钥**：yaml 一律 `${ENV:默认值}`，敏感项默认值留空（见 [`docs/CONFIG_SECRETS.md`](./docs/CONFIG_SECRETS.md)）。
- **profile 决定连哪个库**：`-Pdev` → `smart_admin_v3`，`-Pprod` → `letmedoit`；生产必须用 prod 包。
- 登录联调：`wx.miniapp.mock=true` 用假 code（e2e 必须）；真实模式 appid 须与小程序 `project.config.json` 一致。
- 完整分层规范、禁项清单与踩坑记录见 [`docs/AI-Agent-后端开发规范.md`](./docs/AI-Agent-后端开发规范.md)。

## 目录速览

```
letmedoit-api/
├── sa-base/     # 框架底座（被 sa-admin / sa-app 共同依赖，改动需谨慎）
├── sa-app/      # 小程序接口：auth / member / helper / task / notice / feedback / version / file / wx
├── sa-admin/    # 管理后台（本版本未做业务页面）
├── deploy/      # Docker 部署脚本与 .env 模板
└── docs/        # 开发规范、SQL 脚本（init + updates/<日期>/）、协议与合规文档
```
