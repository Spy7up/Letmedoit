-- ============================================================
-- 「让我做」内容安全检测记录表（增量脚本）
-- ------------------------------------------------------------
-- 用途：小程序审核要求所有 UGC 文本与图片必须过微信内容安全接口。
--       本表留存每次调用的结果：
--         - 文本检测（msgSecCheck，同步）：biz_type='text'，trace_id 为空
--         - 图片检测（mediaCheckAsync，异步）：trace_id 用来和推送结果对上号
--
-- 适用：已执行过 letmedoit_init.sql 的库，直接跑本脚本即可（幂等）。
--       全新库不用跑，init.sql 里已经包含。
-- ============================================================

CREATE TABLE IF NOT EXISTS `t_content_check` (
  `check_id`      bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `trace_id`      varchar(64)      DEFAULT NULL COMMENT '微信异步检测任务ID（文本检测为空）',
  `member_id`     bigint(20) unsigned DEFAULT NULL COMMENT '提交检测的会员ID',
  `biz_type`      varchar(32)      NOT NULL DEFAULT 'text' COMMENT '来源 text/avatar/task_image/task_proof',
  `scene`         tinyint(4)       NOT NULL DEFAULT 4 COMMENT '场景 1资料 2评论 3论坛 4社交日志',
  `media_url`     varchar(512)     DEFAULT NULL COMMENT '被检测的图片地址',
  `media_type`    tinyint(4)       NOT NULL DEFAULT 2 COMMENT '1音频 2图片 0文本',
  `content_brief` varchar(128)     DEFAULT NULL COMMENT '文本摘要，排查用',
  `status`        tinyint(4)       NOT NULL DEFAULT 0 COMMENT '0审核中 1通过 2违规 3检测失败',
  `label`         int(11)          DEFAULT NULL COMMENT '命中标签 100正常 20001时政 20002色情 20006违法 21000其他',
  `suggest`       varchar(16)      DEFAULT NULL COMMENT '微信建议 pass/review/risky',
  `err_msg`       varchar(255)     DEFAULT NULL COMMENT '错误信息',
  `create_time`   datetime         NOT NULL COMMENT '创建时间',
  `update_time`   datetime         NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`check_id`),
  KEY `idx_trace` (`trace_id`),
  KEY `idx_status_time` (`status`, `create_time`),
  KEY `idx_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='内容安全检测记录';
