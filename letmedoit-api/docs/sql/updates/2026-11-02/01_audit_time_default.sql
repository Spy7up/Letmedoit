-- ============================================================================
-- 2026-11-02 / 01 —— 自建表 create_time / update_time 补默认值
--
-- 背景（真实故障）：
--   后台「版本管理」新增版本时报
--     java.sql.SQLException: Field 'create_time' doesn't have a default value
--   原因是自建表的 create_time / update_time 是 `datetime NOT NULL` 且没有默认值，
--   而插入依赖应用层显式赋值；一旦某个模块漏写就 500。
--   框架自带表（t_file / t_menu / t_role …）本来就是 DEFAULT current_timestamp()，
--   只有自建表例外，本次把它们对齐。
--
-- 影响：已有数据不变（MODIFY COLUMN 只改列定义，不动行），可重复执行。
-- 说明：只加 DEFAULT，不加 ON UPDATE CURRENT_TIMESTAMP ——
--   更新时间仍由业务代码/XML 显式写入，避免悄悄改掉「谁在什么时候改的」语义。
-- ============================================================================

-- 会员
ALTER TABLE `t_wx_member`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 帮手关系
ALTER TABLE `t_helper`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 帮手申请
ALTER TABLE `t_helper_request`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 内容检测记录
ALTER TABLE `t_content_check`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 协议正文
ALTER TABLE `t_app_agreement`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 协议同意记录（只有 create_time，没有 update_time）
ALTER TABLE `t_app_agreement_record`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间';

-- 问题与反馈
ALTER TABLE `t_app_feedback`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 小程序版本（本次故障表）
ALTER TABLE `t_app_version`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 任务主表
ALTER TABLE `t_task`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 任务参与者
ALTER TABLE `t_task_participant`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 任务事件（只有 create_time，语义是「发生时间」）
ALTER TABLE `t_task_event`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发生时间';

-- 站内通知
ALTER TABLE `t_task_notice`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 微信订单（支付未接，表已预留）
ALTER TABLE `t_wx_order`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    MODIFY COLUMN `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间';

-- 微信支付回调日志（只有 create_time）
ALTER TABLE `t_wx_pay_notify_log`
    MODIFY COLUMN `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间';
