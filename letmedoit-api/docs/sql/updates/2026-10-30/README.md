# 2026-10-30 上线 · 数据库变更

> 新库不要跑这里，直接跑 `docs/sql/init/letmedoit_init.sql`（已包含本次内容）。

## 本次改了什么

| 文件 | 内容 | 是否影响已有数据 |
|---|---|---|
| `01_app_version_admin_menu.sql` | 新增后台「版本管理」页面 1 条，以及查询、新增、修改、发布权限点 4 条 | 否，纯新增 `t_menu` 记录，不修改版本数据 |

对应后台接口：`POST /appVersion/query`、`POST /appVersion/add`、`POST /appVersion/update`、`POST /appVersion/publish`。

## 执行顺序

前置：已执行 `updates/2026-10-29/01_admin_menu.sql`，存在「让我做运营」目录。

```bash
mysql -h <host> -u <user> -p <库名> --default-character-set=utf8mb4 < 01_app_version_admin_menu.sql
```

脚本可重复执行，不写死菜单 ID，不默认授权给普通角色。执行后需重新登录刷新菜单和权限；普通角色在「角色管理」中按需授权，发布权限建议单独控制。

## 验证

```sql
-- 应返回 5 行：1 个页面 + 4 个权限点
SELECT menu_name, menu_type, path, component, api_perms
FROM t_menu
WHERE deleted_flag = 0
  AND (path = '/letmedoit/version' OR api_perms LIKE 'appVersion:%')
ORDER BY menu_type, menu_name;
```

## 回滚

```sql
-- 先清角色关联，再按本次稳定标识精确删除
DELETE rm FROM t_role_menu rm
JOIN t_menu m ON m.menu_id = rm.menu_id
WHERE m.path = '/letmedoit/version' OR m.api_perms LIKE 'appVersion:%';

DELETE FROM t_menu
WHERE path = '/letmedoit/version' OR api_perms LIKE 'appVersion:%';
```
