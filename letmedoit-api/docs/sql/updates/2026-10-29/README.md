# 2026-10-29 上线 · 数据库变更

> 新库不要跑这里，直接跑 `docs/sql/init/letmedoit_init.sql`（已包含本次内容）。

## 本次改了什么

| 文件 | 内容 | 是否影响已有数据 |
|---|---|---|
| `01_admin_menu.sql` | 后台菜单树新增「让我做运营」目录 1 条、页面 7 条（会员详情 / 任务详情 `visible_flag=0` 隐藏）、按钮权限点 6 条 | 否，纯新增 `t_menu` 记录 |
| `02_remove_demo_menu.sql` | 下线 60 条演示/框架菜单：功能Demo 整棵树（商品、分类、公告、企业）+ 文档中心里的帮助文档 / 更新日志 / 框架意见反馈，及其全部权限点 | **是**，`DELETE t_menu` + `t_role_menu`；前端对应页面与 sa-admin 示例模块已同步删除 |
| `04_clean_orphan_menu.sql` | 清理 2 条历史孤儿菜单：`85 组件演示`（父级 84 不存在、组件也不存在）+ `113 查询`（无主权限点），逻辑是循环清「父级不存在」的记录 | 否，只删 `t_menu`/`t_role_menu` 里的孤儿记录 |
| `03_drop_demo_tables.sql` | 物理删除 12 张遗留表：`t_goods`/`t_category`、`t_oa_*` 4 张、`t_help_doc*` 4 张、`t_change_log`、`t_feedback` | **是，不可回滚**，`DROP TABLE`；执行前必须备份（脚本头部给了 mysqldump 命令） |

对应功能：

- 运营报表：会员、帮手、任务、准时率总览，接口 `/dashboard/*`、`/member/*`、`/helper/*`、`/task/*`
- 小程序反馈处理：`/appFeedback/query|detail|reply`
- 前端页面在 `letmedoit-admin/src/views/business/letmedoit/`，规范见 `doc/design/管理后台开发技术规范.md`

## 执行顺序

```bash
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 01_admin_menu.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 02_remove_demo_menu.sql
# 03 会真的删表，先备份再执行
mysqldump -h <host> -u <user> -p <库名> \
  t_goods t_category t_oa_bank t_oa_enterprise t_oa_enterprise_employee t_oa_invoice \
  t_help_doc t_help_doc_catalog t_help_doc_relation t_help_doc_view_record \
  t_change_log t_feedback > backup_demo_tables_20261029.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 03_drop_demo_tables.sql
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 04_clean_orphan_menu.sql
```

顺序不能反：`02` 先删菜单（否则后台还挂着指向已删表/已删接口的页面），`03` 再删表，`04` 收尾清孤儿菜单。

脚本幂等：父级菜单按 `path` 查询、每条插入都有 `NOT EXISTS` 兜底，重复执行不会产生重复菜单。

> 跑完**让员工重新登录**（或后台清一次菜单缓存）：登录时才会把新菜单与权限点下发到前端。

## 验证

```sql
-- 1) 目录 + 页面 + 权限点数量：1 / 7 / 6
SELECT menu_type, COUNT(*) FROM t_menu
 WHERE deleted_flag = 0
   AND (path LIKE '/letmedoit%'
        OR api_perms IN ('dashboard:query','member:query','helper:query','task:query','appFeedback:query','appFeedback:reply'))
 GROUP BY menu_type;

-- 2) 两个详情页必须是隐藏、但带 path（否则路由注册不上）
SELECT menu_name, path, component, visible_flag FROM t_menu
 WHERE path IN ('/letmedoit/member/detail', '/letmedoit/task/detail');   -- visible_flag 全为 0

-- 3) 权限点与后端 @SaCheckPermission 对齐
SELECT api_perms FROM t_menu WHERE deleted_flag = 0 AND menu_type = 3
   AND api_perms LIKE '%query%' AND (api_perms LIKE 'dashboard%' OR api_perms LIKE 'member%'
       OR api_perms LIKE 'helper%' OR api_perms LIKE 'task%' OR api_perms LIKE 'appFeedback%');

-- 4) 演示菜单已清空：下面应为 0
SELECT COUNT(*) FROM t_menu WHERE deleted_flag = 0
   AND (menu_name = '功能Demo'
        OR path IN ('/goods','/erp/goods/list','/erp/catalog/goods','/erp/catalog/custom',
                    '/oa/notice/notice-list','/oa/enterprise/enterprise-list',
                    '/help-doc/help-doc-manage-list','/feedback/feedback-list',
                    '/support/change-log/change-log-list')
        OR api_perms LIKE 'goods:%' OR api_perms LIKE 'category:%' OR api_perms LIKE 'oa:%');
```

## 回滚

`01` 的回滚：

```sql
-- 只删本次新增的 14 条，按 api_perms / path 精确定位，不要按 menu_id 区间删
DELETE FROM t_menu WHERE path LIKE '/letmedoit%';
DELETE FROM t_menu WHERE api_perms IN
  ('dashboard:query','member:query','helper:query','task:query','appFeedback:query','appFeedback:reply');
```

`02` 的回滚：菜单已被物理删除，**没有 SQL 能还原**。真要恢复只能重跑 `init/letmedoit_init.sql` 里 `t_menu` 段（会把后台菜单重置成基线），或用 `03` 头部备份的前置备份。所以执行前先备份：

```bash
mysqldump -h <host> -u <user> -p <库名> t_menu t_role_menu > backup_menu_20261029.sql
```

`03` 的回滚：**只能靠备份恢复**。`03` 只删表，表里本来就没有业务数据（都是演示/框架数据），恢复价值主要在开发环境。

执行任一脚本后都需要**重新登录**刷新权限。
