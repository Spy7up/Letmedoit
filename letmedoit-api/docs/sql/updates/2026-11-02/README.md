# 2026-11-02 上线 · 数据库变更

> 新库不要跑这里，直接跑 `docs/sql/init/letmedoit_init.sql`（已包含本次内容）。

## 本次改了什么

| 文件 | 内容 | 是否影响已有数据 |
|---|---|---|
| `01_audit_time_default.sql` | 14 张自建表的 `create_time` / `update_time`（共 25 列）补 `DEFAULT CURRENT_TIMESTAMP` | 否，`MODIFY COLUMN` 只改列定义，不动已有行 |
| `02_clean_brand_config.sql` | 删除「万能密码」配置、修正 `t_notice.document_number` 列注释、修正等保配置 remark、删除 2 条框架示例定时作业 | 删除 1 条 `t_config` + 2 条 `t_smart_job`（均为框架遗留、未被业务使用） |
| `03_package_rename.sql` | `t_smart_job.job_class` 从 `net.lab1024.*` 改为 `net.letmedoit.*` | 改 1 列，**必须先跑再启动新代码** |

## 执行顺序

```bash
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 01_audit_time_default.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 02_clean_brand_config.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 03_package_rename.sql
```

三个脚本都可重复执行，不需要停服。**03 必须在启动新代码之前执行**，否则
`TaskScheduleJob` 启动自检会报「未在 t_smart_job 注册」，预约生效与到期提醒静默不跑。

## 代码侧配套改动（同一次提交）

1. **包名全量重构**：`net.lab1024.sa.*` → `net.letmedoit.sa.*`（612 个 java、4 个 pom、
   全部 mapper XML namespace、`@MapperScan` 常量、`spring.factories`、yaml 日志级别）。
2. **作者信息统一**：所有 `@Author 1024创新实验室…` → `@author letmedoit`，
   删除 `@Wechat/@Email/@Copyright/@Date` 与官网外链（含 Swagger 摘要里的署名）。
3. **万能密码**：`LoginService` 增加空值判断（`superPassword != null && !isEmpty()`），
   配合删配置，未配置即视为不启用。
4. 管理端：`package.json` 作者/仓库、页面注释、logo（换成 `logo-mark.svg`）、
   favicon（绿底白勾）、主题文件名 `smart-admin.less` → `letmedoit.less`。

## 验证

```sql
-- 1) 万能密码应为 0 行
SELECT COUNT(1) FROM t_config WHERE config_key = 'super_password';
-- 2) 定时作业应为 1 行且包名已更新
SELECT job_name, job_class, enabled_flag FROM t_smart_job;
-- 3) 审计字段默认值应为 25 行，且 column_default 全为 current_timestamp()
SELECT table_name, column_name, column_default
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND column_name IN ('create_time','update_time')
  AND table_name IN ('t_wx_member','t_helper','t_helper_request','t_content_check',
                     't_app_agreement','t_app_agreement_record','t_app_feedback','t_app_version',
                     't_task','t_task_participant','t_task_event','t_task_notice',
                     't_wx_order','t_wx_pay_notify_log');
```

业务验证：后台「版本管理」新增草稿版本不再报 `create_time`；后台可正常登录（万能密码已失效）。

## 回滚

```sql
-- 包名回滚（仅当代码也回滚到 net.lab1024 时）
UPDATE t_smart_job SET job_class = REPLACE(job_class,'net.letmedoit.','net.lab1024.')
WHERE job_class LIKE 'net.letmedoit.%';
```

`02` 的删除操作不可恢复；如需保留万能密码能力，在后台「参数配置」手动新增
`super_password` 并立即用完清除。


对应代码修复（同一次提交）：

- `sa-admin/.../version/service/AppVersionService.java#add`：新增版本时显式写入 `create_time` / `update_time`；
- `sa-app` / `sa-admin` 自有业务实体的时间字段补 `@TableField(fill = FieldFill.INSERT)` /
  `@TableField(fill = FieldFill.INSERT_UPDATE)`，让 `MybatisPlusFillHandler` 真正生效
  （此前全项目没有任何实体带 `fill` 注解，`TableInfo#isWithInsertFill()` 恒为 false，填充器是死代码）。

## 为什么改

后台「版本管理」新增版本直接 500：

```
java.sql.SQLException: Field 'create_time' doesn't have a default value
```

`t_app_version` 的 `create_time` / `update_time` 是 `NOT NULL` 且无默认值，而插入只带了其他列。
框架自带表（`t_file` / `t_menu` / `t_role` …）本来就是 `DEFAULT current_timestamp()`，
只有自建表例外，本次把它们对齐，避免同类问题再出现。

## 执行顺序

无前置，单独执行即可：

```bash
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 01_audit_time_default.sql
```

脚本可重复执行（`MODIFY COLUMN` 幂等），不需要停服。若某张表在目标库中不存在（例如
`t_wx_order` 未建），对应语句会报 `Table doesn't exist`，删掉那一段再跑其余部分即可。

## 验证

```sql
-- 应返回 25 行，且 column_default 全为 current_timestamp()
SELECT table_name, column_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name IN ('t_wx_member','t_helper','t_helper_request','t_content_check',
                     't_app_agreement','t_app_agreement_record','t_app_feedback','t_app_version',
                     't_task','t_task_participant','t_task_event','t_task_notice',
                     't_wx_order','t_wx_pay_notify_log')
  AND column_name IN ('create_time','update_time')
ORDER BY table_name, column_name;
```

业务验证：后台「版本管理」新增一条草稿版本，不再报 `create_time` 错。

## 回滚

```sql
-- 仅回滚列定义（已有数据不受影响）；按需选表执行
ALTER TABLE `t_app_version`
    MODIFY COLUMN `create_time` datetime NOT NULL COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL COMMENT '更新时间';
```

回滚数据库后必须同时回滚代码，否则代码不再显式写时间，插入会重新报错。
