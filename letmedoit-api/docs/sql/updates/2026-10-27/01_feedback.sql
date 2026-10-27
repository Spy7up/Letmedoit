-- ============================================================================
--  2026-10-27 / 01 · 问题与反馈
-- ----------------------------------------------------------------------------
--  做了什么：
--    * 新增 t_app_feedback（小程序「我的 → 问题与反馈」提交，后台处理）
--    * 新增两本字典 FEEDBACK_TYPE / FEEDBACK_STATUS（类型与状态的文案来源）
--
--  幂等：建表 IF NOT EXISTS；字典先查后插，重复执行不报错。
--  ⚠️ 字典缓存是 Redis：跑完必须重启服务或清 dict 缓存，否则后台/接口读不到新字典。
-- ============================================================================

CREATE TABLE IF NOT EXISTS `t_app_feedback` (
  `feedback_id`     bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '反馈ID',
  `member_id`       bigint(20) unsigned NOT NULL COMMENT '提交人会员ID',
  `type`            tinyint(4)   NOT NULL COMMENT '反馈类型 1功能建议 2使用问题 3内容违规 4其他',
  `content`         varchar(500) NOT NULL COMMENT '反馈内容',
  `images`          varchar(2000) DEFAULT NULL COMMENT '反馈图片，JSON 数组字符串，最多 3 张公网 URL',
  `contact`         varchar(64)  DEFAULT NULL COMMENT '联系方式（选填，方便后台回复）',
  `status`          tinyint(4)   NOT NULL DEFAULT 0 COMMENT '处理状态 0待处理 1处理中 2已解决 3已关闭',
  `reply_content`   varchar(500) DEFAULT NULL COMMENT '处理回复',
  `reply_member_id` bigint(20) unsigned DEFAULT NULL COMMENT '处理人（后台员工ID）',
  `reply_time`      datetime     DEFAULT NULL COMMENT '回复时间',
  `deleted_flag`    tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time`     datetime     NOT NULL COMMENT '创建时间',
  `update_time`     datetime     NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`feedback_id`),
  KEY `idx_status_time` (`status`, `create_time`),
  KEY `idx_type_time` (`type`, `create_time`),
  KEY `idx_member_time` (`member_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='问题与反馈';

-- ---------------- 字典主表 ----------------
INSERT INTO `t_dict` (`dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`)
SELECT '反馈类型', 'FEEDBACK_TYPE', 't_app_feedback.type：后台分派用（内容违规要当天处理）', 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict` WHERE `dict_code` = 'FEEDBACK_TYPE');

INSERT INTO `t_dict` (`dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`)
SELECT '反馈状态', 'FEEDBACK_STATUS', 't_app_feedback.status：后台处理流转', 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict` WHERE `dict_code` = 'FEEDBACK_STATUS');

-- ---------------- 字典项 ----------------
SET @feedback_type = (SELECT `dict_id` FROM `t_dict` WHERE `dict_code` = 'FEEDBACK_TYPE' LIMIT 1);
SET @feedback_status = (SELECT `dict_id` FROM `t_dict` WHERE `dict_code` = 'FEEDBACK_STATUS' LIMIT 1);

INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_type, '1', '功能建议', '#6B5BD2', '想要什么功能', 40, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_type AND `data_value` = '1');
INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_type, '2', '使用问题', '#E08A00', '用不了、报错、显示不对', 30, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_type AND `data_value` = '2');
INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_type, '3', '内容违规', '#D64545', '看到不合适的内容，优先处理', 20, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_type AND `data_value` = '3');
INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_type, '4', '其他', '#8C8279', '', 10, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_type AND `data_value` = '4');

INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_status, '0', '待处理', '#E08A00', '', 40, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_status AND `data_value` = '0');
INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_status, '1', '处理中', '#D64C28', '', 30, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_status AND `data_value` = '1');
INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_status, '2', '已解决', '#17A67C', '', 20, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_status AND `data_value` = '2');
INSERT INTO `t_dict_data` (`dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`)
SELECT @feedback_status, '3', '已关闭', '#8C8279', '重复反馈 / 无需处理', 10, 0, NOW(), NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `t_dict_data` WHERE `dict_id` = @feedback_status AND `data_value` = '3');

-- ---------------- 验证 ----------------
-- SELECT d.dict_code, dd.data_value, dd.data_label
--   FROM t_dict d JOIN t_dict_data dd ON dd.dict_id = d.dict_id
--  WHERE d.dict_code IN ('FEEDBACK_TYPE','FEEDBACK_STATUS')
--  ORDER BY d.dict_code, dd.sort_order DESC;   -- 应为 4 + 4 行
-- SELECT COUNT(*) FROM t_app_feedback;         -- 0（没有测试数据）
