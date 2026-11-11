-- ============================================================================
-- 2026-10-29 / 02_remove_demo_menu.sql
-- 下线 SmartAdmin 自带演示菜单与「文档中心」里的框架自建功能（幂等）
--
-- 删除范围（共 60 条：14 个目录/页面 + 46 个按钮权限点）：
--   1. 功能Demo 整棵树：商品管理 / 商品分类 / 自定义分组 / 公告管理 / 企业管理（含隐藏详情页）
--   2. 文档中心下的框架功能：帮助文档、意见反馈（t_feedback）、更新日志
--   3. 上述菜单的全部 api_perms 权限点（goods:* / category:* / oa:* / support:helpDoc* / support:changeLog*）
--
-- 不动的：组织架构、系统设置、监控服务、运维工具、网络安全、代码生成、knife4j/swagger
-- 说明：小程序侧「问题与反馈」用的是 t_app_feedback + appFeedback:*，与本脚本删除的框架 feedback:* 无关。
-- ============================================================================
SET NAMES utf8mb4;

-- ----------------------------------------------------------------------------
-- 1. 收集要删除的菜单（先父级/页面，再按权限字符串补全按钮）
--    用临时表避免 MySQL 的 "You can't specify target table for update in FROM clause"
-- ----------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `tmp_lmd_remove_menu`;
CREATE TEMPORARY TABLE `tmp_lmd_remove_menu` (`menu_id` bigint NOT NULL PRIMARY KEY);

-- 目录与页面（ID 取自 init 基线）
INSERT IGNORE INTO `tmp_lmd_remove_menu` (`menu_id`) VALUES
  (47),  -- 商品管理
  (48),  -- 商品管理（目录）
  (78),  -- 商品分类
  (79),  -- 自定义分组
  (132), -- 公告管理
  (138), -- 功能Demo（目录）
  (142), -- 公告详情（隐藏）
  (144), -- 企业管理
  (145), -- 企业详情（隐藏）
  (147), -- 帮助文档
  (148), -- 意见反馈（框架 t_feedback）
  (149), -- 我的通知（OA 公告）
  (150), -- 我的通知公告详情（隐藏）
  (152); -- 更新日志

-- 按钮权限点：父级在上面这批里，或权限字符串属于被下线模块
INSERT IGNORE INTO `tmp_lmd_remove_menu` (`menu_id`)
SELECT `menu_id`
  FROM `t_menu`
 WHERE `menu_type` = 3
   AND `deleted_flag` = 0
   AND (`parent_id` IN (47, 48, 78, 79, 132, 138, 142, 144, 145, 147, 148, 149, 150, 152)
        OR `api_perms` LIKE 'goods:%'
        OR `api_perms` LIKE 'category:%'
        OR `api_perms` LIKE 'oa:%'
        OR `api_perms` LIKE 'support:helpDoc%'
        OR `api_perms` LIKE 'support:changeLog%');

-- ----------------------------------------------------------------------------
-- 2. 先清角色授权，再删菜单
-- ----------------------------------------------------------------------------
DELETE FROM `t_role_menu` WHERE `menu_id` IN (SELECT `menu_id` FROM `tmp_lmd_remove_menu`);
DELETE FROM `t_menu` WHERE `menu_id` IN (SELECT `menu_id` FROM `tmp_lmd_remove_menu`);

DROP TEMPORARY TABLE `tmp_lmd_remove_menu`;

-- ----------------------------------------------------------------------------
-- 3. 兜底：清掉父菜单已不存在的按钮权限点（历史手工删菜单留下的孤儿）
-- ----------------------------------------------------------------------------
DELETE FROM `t_menu`
 WHERE `menu_type` = 3
   AND `deleted_flag` = 0
   AND `parent_id` NOT IN (SELECT `menu_id` FROM (SELECT `menu_id` FROM `t_menu`) t);

-- ----------------------------------------------------------------------------
-- 4. 自检
-- ----------------------------------------------------------------------------
-- 4.1 演示与文档中心菜单应为 0 条
-- SELECT COUNT(*) FROM t_menu
--  WHERE deleted_flag = 0
--    AND (menu_name = '功能Demo' OR path IN ('/goods','/erp/goods/list','/erp/catalog/goods','/erp/catalog/custom',
--        '/oa/notice/notice-list','/oa/enterprise/enterprise-list','/help-doc/help-doc-manage-list',
--        '/feedback/feedback-list','/support/change-log/change-log-list'));
--
-- 4.2 剩下的菜单应为：组织架构 / 系统设置 / 监控服务 / 运维工具 / 网络安全 / 文档中心(knife4j、swagger) / 让我做运营
-- SELECT menu_name, path FROM t_menu WHERE deleted_flag = 0 AND menu_type IN (1, 2) ORDER BY parent_id, sort;
