-- ============================================================================
-- 2026-10-30 / 01_app_version_admin_menu.sql
-- 让我做管理后台：版本管理页面 + 按钮权限（幂等，可重复执行）
-- 前置：已执行 2026-10-29/01_admin_menu.sql，存在 path=/letmedoit 的目录。
-- ============================================================================
SET NAMES utf8mb4;

-- 1. 版本管理页面
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本管理', 2, p.menu_id, 8, '/letmedoit/version', '/business/letmedoit/version/version-list.vue', NULL, NULL, NULL, 'DeploymentUnitOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 2. 查询权限
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:query', 'appVersion:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:query' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 3. 新增权限
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本新增', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:add', 'appVersion:add', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:add' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 4. 修改权限
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本修改', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:update', 'appVersion:update', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:update' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 5. 发布权限（独立于普通修改）
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本发布', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:publish', 'appVersion:publish', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:publish' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 验证：应返回 1 个版本管理页面 + 4 个权限点。
-- SELECT menu_name, menu_type, path, api_perms FROM t_menu
--  WHERE deleted_flag = 0 AND (path = '/letmedoit/version' OR api_perms LIKE 'appVersion:%');
