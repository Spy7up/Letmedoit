-- ============================================================================
-- 2026-10-29 / 01_admin_menu.sql
-- 让我做管理后台：运营菜单树 + 按钮权限（幂等，可重复执行）
--
-- 说明：
--   1. 新增一级目录「让我做运营」（path=/letmedoit），下挂 5 个可见页面与 2 个隐藏详情页；
--   2. 详情页 visible_flag=0：不在左侧导航展示，但会注册成路由（buildRoutes 只按 path 过滤），
--      列表页用 router.push 带 query 跳转；
--   3. 按钮权限点 api_perms 与后端 @SaCheckPermission 一一对应，缺了按钮消失、接口 403；
--   4. 不写死 menu_id，父级 ID 通过 path 查询；重复执行不会产生重复菜单。
-- ============================================================================
SET NAMES utf8mb4;

-- ----------------------------------------------------------------------------
-- 1. 一级目录：让我做运营
-- ----------------------------------------------------------------------------
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '让我做运营', 1, 0, 2, '/letmedoit', NULL, NULL, NULL, NULL, 'AppstoreOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- ----------------------------------------------------------------------------
-- 2. 页面菜单
-- ----------------------------------------------------------------------------
-- 运营概览
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '运营概览', 2, p.menu_id, 1, '/letmedoit/dashboard', '/business/letmedoit/dashboard/index.vue', NULL, NULL, NULL, 'DashboardOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/dashboard' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 会员管理
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '会员管理', 2, p.menu_id, 2, '/letmedoit/member', '/business/letmedoit/member/member-list.vue', NULL, NULL, NULL, 'TeamOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/member' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 会员详情（隐藏，列表页跳转）
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '会员详情', 2, p.menu_id, 3, '/letmedoit/member/detail', '/business/letmedoit/member/member-detail.vue', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, 0, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/member/detail' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 帮手关系
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '帮手关系', 2, p.menu_id, 4, '/letmedoit/helper', '/business/letmedoit/helper/helper-list.vue', NULL, NULL, NULL, 'LinkOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/helper' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 任务管理
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '任务管理', 2, p.menu_id, 5, '/letmedoit/task', '/business/letmedoit/task/task-list.vue', NULL, NULL, NULL, 'ScheduleOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/task' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 任务详情（隐藏）
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '任务详情', 2, p.menu_id, 6, '/letmedoit/task/detail', '/business/letmedoit/task/task-detail.vue', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, 0, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/task/detail' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 小程序反馈
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '小程序反馈', 2, p.menu_id, 7, '/letmedoit/feedback', '/business/letmedoit/feedback/feedback-list.vue', NULL, NULL, NULL, 'MessageOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/feedback' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- ----------------------------------------------------------------------------
-- 3. 按钮权限点（与后端 @SaCheckPermission 一一对应）
-- ----------------------------------------------------------------------------
-- 运营概览：查询
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '概览查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'dashboard:query', 'dashboard:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/dashboard' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'dashboard:query' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 会员管理：查询
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '会员查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'member:query', 'member:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/member' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'member:query' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 帮手关系：查询
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '帮手查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'helper:query', 'helper:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/helper' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'helper:query' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 任务管理：查询
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '任务查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'task:query', 'task:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/task' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'task:query' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 小程序反馈：查询
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '反馈查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'appFeedback:query', 'appFeedback:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/feedback' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appFeedback:query' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- 小程序反馈：处理
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '反馈处理', 3, c.menu_id, NULL, NULL, NULL, 1, 'appFeedback:reply', 'appFeedback:reply', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/feedback' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appFeedback:reply' AND `deleted_flag` = 0 LIMIT 1) tmp);

-- ----------------------------------------------------------------------------
-- 4. 自检：应为 1 个目录 + 7 个页面（其中 2 个隐藏）+ 6 个权限点
-- ----------------------------------------------------------------------------
-- SELECT menu_type, COUNT(*) FROM t_menu
--  WHERE deleted_flag = 0 AND (path LIKE '/letmedoit%' OR api_perms LIKE 'dashboard:query'
--        OR api_perms LIKE 'member:query' OR api_perms LIKE 'helper:query' OR api_perms LIKE 'task:query'
--        OR api_perms LIKE 'appFeedback:%')
--  GROUP BY menu_type;
