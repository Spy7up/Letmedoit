# 2026-10-27 上线 · 数据库变更

> 这是「日期目录」规则的第一个版本，规则见上级 `docs/sql/README.md`。
> 新库不要跑这里，直接跑 `docs/sql/init/letmedoit_init.sql`。

## 本次改了什么

| 文件 | 内容 | 是否影响已有数据 |
|---|---|---|
| `01_feedback.sql` | 新增 `t_app_feedback`（问题与反馈）+ 字典 `FEEDBACK_TYPE` / `FEEDBACK_STATUS` | 否，纯新增 |
| `02_version.sql` | 新增 `t_app_version`（小程序版本）+ 当前版本 `v1.1.0` | 否，纯新增 |
| `03_agreement_author.sql` | 协议正文运营者改为「本小程序作者」、联系方式改为小程序内反馈入口；顺带补齐缺失的协议正文 | 是，只改 `t_app_agreement.content` |
| `04_version_1_0_0.sql` | 版本记录对齐实际提审版本 1.0.0（此前种子是 1.1.0） | 是，只切 `t_app_version.current_flag` |

对应功能：

- 问题与反馈：小程序「我的 → 问题与反馈」，接口 `/api/feedback/*`，见 `docs/问题与反馈.md`
- 版本管理：`/api/version/current`，「我的」页脚与关于弹窗的版本文案，见 `docs/版本管理.md`
- 协议正文：见 `docs/AGREEMENT.md` 第 2 节（不写真实姓名/邮箱的理由与规则）

## 执行顺序

```bash
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 01_feedback.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 02_version.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 03_agreement_author.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 04_version_1_0_0.sql
```

四个脚本都是幂等的，重复执行不会报错，也不会重复插数据。

> `01` 涉及字典：跑完**重启服务**（或清 Redis 的 `dict` 缓存），否则类型下拉可能读不到。

## 验证

```sql
-- 1) 新表存在
SELECT table_name FROM information_schema.tables
 WHERE table_schema = DATABASE()
   AND table_name IN ('t_app_feedback', 't_app_version');

-- 2) 反馈字典 4 + 4 条
SELECT d.dict_code, COUNT(x.dict_data_id) items
  FROM t_dict d LEFT JOIN t_dict_data x ON x.dict_id = d.dict_id
 WHERE d.dict_code IN ('FEEDBACK_TYPE', 'FEEDBACK_STATUS')
 GROUP BY d.dict_code;

-- 3) 版本只有一行当前版本
SELECT app_type, version, version_label, current_flag FROM t_app_version;
SELECT app_type, COUNT(1) c FROM t_app_version
 WHERE current_flag = 1 AND deleted_flag = 0 GROUP BY app_type;   -- c = 1

-- 4) 协议正文：无占位符、无邮箱、无住所地，运营者是作者
SELECT type, version, enabled_flag,
       (content LIKE '%〔%') has_placeholder,
       (content LIKE '%@%')  has_email,
       (content LIKE '%住所地%') has_domicile
  FROM t_app_agreement WHERE enabled_flag = 1;   -- 三个标记列都应为 0
```

## 回滚

- `01` / `02` 是纯新增：`DROP TABLE t_app_feedback; DROP TABLE t_app_version;`（连同字典项一起删即可）
- `03` 只改正文：从备份恢复 `t_app_agreement.content`。**不要**指望反向 REPLACE 能还原。

> 生产执行前先 `mysqldump` 备份 `t_app_agreement` 这一张表就够了。
