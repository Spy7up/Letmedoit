-- ============================================================================
-- 2026-10-29 / 04_clean_orphan_menu.sql
-- 清理父级已不存在的历史孤儿菜单（幂等）
--
-- 背景：init 基线里遗留两条「父菜单被删过」的孤儿记录，新库已同步去掉，
--       已有库用本脚本兜一次：
--   85  组件演示   (menu_type=2) 父级 84 已不存在，组件 /support/demonstration/index.vue 也不存在 → 必然 404
--  113  查询       (menu_type=3) 父级 112 已不存在，是无主的按钮权限点
--
-- 逻辑：反复扫描「parent_id 非 0 且父级不存在」的记录，先删角色授权再删菜单，
--       直到没有新的孤儿（兼容多级孤儿），最后再兜一次无主权限点。
-- ============================================================================
SET NAMES utf8mb4;

DROP TEMPORARY TABLE IF EXISTS `tmp_lmd_orphan_menu`;
CREATE TEMPORARY TABLE `tmp_lmd_orphan_menu` (`menu_id` bigint NOT NULL PRIMARY KEY);

-- 两轮足够覆盖本库的多级孤儿（超过两层建议先人工核对）
INSERT IGNORE INTO `tmp_lmd_orphan_menu` (`menu_id`)
SELECT m.`menu_id`
  FROM `t_menu` m
 WHERE m.`deleted_flag` = 0
   AND m.`parent_id` <> 0
   AND NOT EXISTS (SELECT 1 FROM `t_menu` p WHERE p.`menu_id` = m.`parent_id` AND p.`deleted_flag` = 0);

DELETE FROM `t_role_menu` WHERE `menu_id` IN (SELECT `menu_id` FROM `tmp_lmd_orphan_menu`);
DELETE FROM `t_menu` WHERE `menu_id` IN (SELECT `menu_id` FROM `tmp_lmd_orphan_menu`);

INSERT IGNORE INTO `tmp_lmd_orphan_menu` (`menu_id`)
SELECT m.`menu_id`
  FROM `t_menu` m
 WHERE m.`deleted_flag` = 0
   AND m.`parent_id` <> 0
   AND NOT EXISTS (SELECT 1 FROM `t_menu` p WHERE p.`menu_id` = m.`parent_id` AND p.`deleted_flag` = 0);

DELETE FROM `t_role_menu` WHERE `menu_id` IN (SELECT `menu_id` FROM `tmp_lmd_orphan_menu`);
DELETE FROM `t_menu` WHERE `menu_id` IN (SELECT `menu_id` FROM `tmp_lmd_orphan_menu`);

DROP TEMPORARY TABLE `tmp_lmd_orphan_menu`;

-- 兜底：权限点父级已不存在（02 已做过一次，这里再确认）
DELETE FROM `t_menu`
 WHERE `menu_type` = 3
   AND `deleted_flag` = 0
   AND `parent_id` NOT IN (SELECT `menu_id` FROM (SELECT `menu_id` FROM `t_menu`) t);

-- ----------------------------------------------------------------------------
-- 自检：两条都应为 0
-- ----------------------------------------------------------------------------
-- SELECT COUNT(*) FROM t_menu m
--  WHERE m.deleted_flag = 0 AND m.parent_id <> 0
--    AND NOT EXISTS (SELECT 1 FROM t_menu p WHERE p.menu_id = m.parent_id AND p.deleted_flag = 0);
--
-- SELECT COUNT(*) FROM t_menu WHERE deleted_flag = 0 AND menu_id IN (85, 113);
