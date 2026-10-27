-- ============================================================================
--  2026-10-27 / 02 · 小程序版本管理
-- ----------------------------------------------------------------------------
--  做了什么：
--    * 新增 t_app_version：小程序所有版本文案改由接口下发（/api/version/current）
--    * 种入当前版本 v1.1.0（没有当前版本时接口返回空，前端只是不显示版本号）
--
--  幂等：建表 IF NOT EXISTS；只有「当前端没有 current_flag=1」时才插种子。
-- ============================================================================

CREATE TABLE IF NOT EXISTS `t_app_version` (
  `version_id`        bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app_type`          varchar(16)  NOT NULL DEFAULT 'miniapp' COMMENT '端类型 miniapp 微信小程序（预留 h5/app）',
  `version`           varchar(32)  NOT NULL COMMENT '版本号，如 1.1.0（不带 v）',
  `version_label`     varchar(32)  DEFAULT NULL COMMENT '展示用版本号，如 v1.1.0；空则服务端拼 v+version',
  `release_note`      varchar(500) DEFAULT NULL COMMENT '更新说明，「关于」弹窗展示',
  `release_time`      datetime     DEFAULT NULL COMMENT '发布时间',
  `min_base_lib`      varchar(16)  DEFAULT NULL COMMENT '最低基础库版本（预留）',
  `force_update_flag` tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否强制更新 0否 1是（预留，前端暂不读）',
  `current_flag`      tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否当前对外版本 0否 1是，同一端只应有一行为1',
  `deleted_flag`      tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time`       datetime     NOT NULL COMMENT '创建时间',
  `update_time`       datetime     NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`version_id`),
  UNIQUE KEY `uk_type_version` (`app_type`, `version`),
  KEY `idx_type_current` (`app_type`, `current_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='小程序版本';

INSERT INTO `t_app_version`
  (`app_type`, `version`, `version_label`, `release_note`, `release_time`,
   `min_base_lib`, `force_update_flag`, `current_flag`, `deleted_flag`, `create_time`, `update_time`)
SELECT 'miniapp', '1.1.0', 'v1.1.0', '任务委托与提醒：多人任务、帮手、站内通知', NOW(),
       NULL, 0, 1, 0, NOW(), NOW()
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM `t_app_version`
   WHERE `app_type` = 'miniapp' AND `current_flag` = 1 AND `deleted_flag` = 0
);

-- ---------------- 验证 ----------------
-- SELECT version, version_label, current_flag FROM t_app_version;
-- SELECT app_type, COUNT(1) FROM t_app_version
--  WHERE current_flag = 1 AND deleted_flag = 0 GROUP BY app_type;   -- 每端 1 行
