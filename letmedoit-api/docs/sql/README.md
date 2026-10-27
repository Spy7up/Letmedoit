# 数据库脚本规则（改库前先看这份）

> 所有表结构与初始数据的变更都在这个目录里。**动手改代码前先读完本文**，
> 特别是「每次改动的固定动作」和「禁止事项」两节。
> 项目：smart-admin（sa-base / sa-admin / sa-app）· 数据库：MySQL 8.x

---

## 1. 目录结构

```
docs/sql/
├── README.md                 ← 你正在读的这份（规则 + 变更记录）
├── init/
│   └── letmedoit_init.sql    全量初始化：新建库只跑这一个
└── updates/
    └── 2026-10-27/           每次上线一个「日期」文件夹
        ├── README.md         本次上线做了什么、按什么顺序执行
        ├── 01_feedback.sql
        ├── 02_version.sql
        └── 03_agreement_author.sql
```

两条原则，记住就不会乱：

| 目录 | 给谁用 | 什么时候动 |
|---|---|---|
| `init/letmedoit_init.sql` | **全新库**（生产首次建库、预发、本地重装） | 每次改表/改初始数据都要同步更新，保证它永远等于「所有 updates 跑完后的样子」 |
| `updates/<日期>/` | **已有库**（线上、开发库） | 每次上线新增一个日期目录，放这次上线的增量，不是全量 |

> 日期用上线日期（不是写代码的日期）。同一天上线两次就放同一个日期目录，
> 文件序号继续往后排（`04_xxx.sql`），不要建两个一样的日期目录。

---

## 2. 新库怎么建

```bash
# 1) 建库（名字按环境，生产是 letmedoit，开发是 smart_admin_v3）
mysql -h <host> -u <user> -p -e "CREATE DATABASE letmedoit DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"

# 2) 导入（里面只有建表 + 必需初始数据，没有测试数据）
mysql -h <host> -u <user> -p letmedoit < docs/sql/init/letmedoit_init.sql

# 3) 按文件末尾「六、上线自检」的 SQL 逐条确认
```

导入**字典**之后要重启一次服务（或清 Redis 的 `dict` 缓存），否则字典缓存里是空结果。

---

## 3. 已有库怎么升级

按日期从旧到新，逐个目录、按文件序号执行：

```bash
# 例：从 10-27 版本升到 11-03 版本
mysql -h <host> -u <user> -p letmedoit < docs/sql/updates/2026-10-27/01_feedback.sql
mysql -h <host> -u <user> -p letmedoit < docs/sql/updates/2026-10-27/02_version.sql
mysql -h <host> -u <user> -p letmedoit < docs/sql/updates/2026-10-27/03_agreement_author.sql
mysql -h <host> -u <user> -p letmedoit < docs/sql/updates/2026-11-03/01_xxx.sql
```

- **顺序不能乱**：目录按日期升序、目录内按文件名升序。
- **脚本必须能重复执行**（见第 4 节），跑错了再跑一次不会更糟。
- 执行完按该日期目录里的 `README.md` 尾部的验证 SQL 确认。

---

## 4. 写增量脚本的硬要求

| # | 要求 | 原因 |
|---|---|---|
| 1 | 建表用 `CREATE TABLE IF NOT EXISTS` | 重跑不报错 |
| 2 | 加列/加索引先查 `information_schema` 再 `PREPARE` 执行 | MySQL 8 没有 `ADD COLUMN IF NOT EXISTS` |
| 3 | 插数据用 `INSERT ... SELECT ... WHERE NOT EXISTS` | 重复执行不会主键冲突 |
| 4 | **不要写死自增 ID**；需要关联时用 `SET @id = (SELECT ...)` | 已有库的 ID 和 init 不一样 |
| 5 | 不写 `DROP` / `TRUNCATE` / `DELETE`（除非本次上线明确要清数据，并在 README 里写清范围与备份方式） | 生产不可逆 |
| 6 | 每个脚本末尾用注释写**验证 SQL** | 执行的人不用猜「对了没」 |
| 7 | 文件编码 UTF-8、**LF 换行**、`SET NAMES utf8mb4` 由客户端保证 | CRLF 会让正文类字段带 `\r`，多行文本解析会出问题 |
| 8 | 文件名 `NN_英文短名.sql`，`NN` 两位执行序号 | 排序即执行顺序 |

加列模板（幂等）：

```sql
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_task' AND COLUMN_NAME = 'foo');
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `t_task` ADD COLUMN `foo` varchar(32) DEFAULT NULL COMMENT ''说明'' AFTER `bar`',
  'SELECT ''t_task.foo 已存在，跳过'' AS msg');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
```

---

## 5. 每次改动的固定动作（Agent / 开发都照做）

改表或改初始数据时，**四件事一起做完，缺一不可**：

1. `updates/<今天日期>/NN_xxx.sql` — 写增量（已有库用）
2. `init/letmedoit_init.sql` — 同步改成最新形态（新库用）
3. `updates/<今天日期>/README.md` — 写清本次改了什么、执行顺序、验证点
4. 本文末尾「变更记录」表 — 追加一行

然后验证：

```bash
# 推荐：用两个临时库对比，确认「旧库 + 增量」== 「新 init」
# 1) 旧库：上次版本的 init（或线上备份）
# 2) 新库：本次 init
# 两份 information_schema.tables / columns / 字典项 / 关键初始数据应完全一致
```

只改数据（比如协议正文、字典文案）也要走同样流程：updates 里放 `UPDATE`，init 里同步最终值。

---

## 6. 禁止事项

- ❌ **改已经发布过的 updates 脚本**。线上已经执行过，改了也不会再跑，只会让「脚本 ≠ 实际库」。要修就新加一个序号文件。
- ❌ 把测试数据写进 `init`（会员、任务、帮手、通知、上报记录、测试账号）。`init` 只放运行必需的种子。
- ❌ 在代码里写 `CREATE TABLE` / 启动时自动建表。表结构只有这一个来源。
- ❌ 用 Navicat 之类工具手工改线上表结构后不补脚本。下次建库就会缺。
- ❌ 在脚本里 `USE <库名>` 或写死库名。库名由执行命令决定（生产/开发库名不同）。

---

## 7. 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| 跑完字典，接口还返回旧文案 | 字典有 Redis 缓存：重启服务或清 `dict` 缓存 |
| 表建好了但保存数据报 `Unknown column` | 表被旧脚本同名跳过（如 `t_notice`）。本项目通知表叫 `t_task_notice`，反馈表叫 `t_app_feedback`，名字都刻意避开框架自带的表 |
| `CREATE TABLE IF NOT EXISTS` 没生效 | 库里有同名旧结构，`IF NOT EXISTS` 不会改结构。用 updates 里的 `ALTER` 脚本补 |
| 中文变问号 | 客户端连接字符集不是 utf8mb4；用 `mysql --default-character-set=utf8mb4` |
| 时间差 8 小时 | 连接串 `serverTimezone=Asia/Shanghai`，或建库时 `SET time_zone='+08:00'` |
| 生产库名 | `-Pprod` 打包对应 `letmedoit`；`-Pdev` 对应 `smart_admin_v3`（见 `docs/二次开发指南.md`） |

---

## 8. 为什么现在长这样（历史）

2026-10-26 之前，`docs/sql/` 下散着一堆按功能命名的一次性脚本
（`letmedoit_task.sql`、`letmedoit_dict.sql`、`letmedoit_task_images.sql`…），
谁先谁后靠记忆，新库要按顺序跑六七个文件，还容易漏。

2026-10-27 做了三件事：

1. 把当时的最终结构合并成一份全量 init，并清掉所有联调测试数据；
2. **删掉那批分散脚本**（它们的内容已全部并入 init，留着只会误用）；
3. 从这一版开始，变更一律「日期目录 + 序号文件」，新的 init 随每次发版同步。

所以：**如果你在别处（聊天记录、旧文档）看到 `letmedoit_task.sql` 之类的路径，那是过期的，以本目录为准。**

---

## 9. 变更记录

| 日期 | 目录 | 内容 | 影响 |
|---|---|---|---|
| 2026-10-27 | `updates/2026-10-27/` | 基线重建：新增 `t_app_feedback` + 反馈两本字典；新增 `t_app_version`；协议正文改为「本小程序作者」；版本记录对齐 1.0.0 | 新库直接用 `init/letmedoit_init.sql`；已有库跑该目录 01→04 |

> 新增一行时按日期倒序写（新的在最上面），一行说清「改了什么表/数据」和「跑了会怎样」。
