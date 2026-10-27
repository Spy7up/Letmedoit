-- ============================================================================
--  2026-10-27 / 04 · 版本记录对齐到 1.0.0
-- ----------------------------------------------------------------------------
--  背景：首个上线的小程序包版本号是 1.0.0，而库里的当前版本记录是 1.1.0
--        （init 里的示例值）。版本表是「我的」页与关于弹窗的唯一来源，
--        必须与真实提审版本一致，否则用户看到的是不存在的版本号。
--
--  幂等：先查后插；只切 current_flag，不改历史行。
--  ⚠️ 后续每次发版都要这样做：插新版本行 → 把旧行 current_flag 置 0。
-- ============================================================================

-- 1) 没有 1.0.0 就补一条
INSERT INTO `t_app_version`
  (`app_type`, `version`, `version_label`, `release_note`, `release_time`,
   `min_base_lib`, `force_update_flag`, `current_flag`, `deleted_flag`, `create_time`, `update_time`)
SELECT 'miniapp', '1.0.0', 'v1.0.0', '首个版本：任务委托与提醒（多人任务、帮手、站内通知）', '2026-10-27 00:00:00',
       NULL, 0, 0, 0, NOW(), NOW()
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM `t_app_version` WHERE `app_type` = 'miniapp' AND `version` = '1.0.0'
);

-- 2) 同端其它版本下线
UPDATE `t_app_version`
SET `current_flag` = 0, `update_time` = NOW()
WHERE `app_type` = 'miniapp'
  AND `version` <> '1.0.0'
  AND `current_flag` = 1;

-- 3) 1.0.0 上线
UPDATE `t_app_version`
SET `current_flag` = 1, `update_time` = NOW()
WHERE `app_type` = 'miniapp'
  AND `version` = '1.0.0'
  AND `deleted_flag` = 0;

-- ---------------- 验证 ----------------
-- SELECT version, version_label, current_flag, release_time FROM t_app_version ORDER BY version;
-- SELECT app_type, COUNT(1) c FROM t_app_version
--  WHERE current_flag = 1 AND deleted_flag = 0 GROUP BY app_type;   -- c 必须 = 1
