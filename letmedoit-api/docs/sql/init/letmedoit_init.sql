-- ============================================================================
--  「让我做」(letmedoit) 生产环境数据库初始化脚本
-- ----------------------------------------------------------------------------
--  适用：全新建库（生产/预发），只跑一次。已有库升级请用 docs/sql/updates/。
--  基线日期：2026-10-29     表数量：46 张
--    = 业务 15 张（会员/帮手/任务/通知/文件/内容安全/协议/字典/反馈/版本）
--    + 框架底座 28 张（sa-base 与 sa-admin 自带）
--    + 暂未使用 3 张（订单、支付回调、代码生成配置）
--
--  内容：
--    一、sa-app 小程序运行必需（缺一张，接口就报错）
--    二、sa-base 通用能力（字典 / 定时任务 / 配置 / 登录日志）
--    三、后台管理 sa-admin（本期未做业务页，但表要齐，否则后台起不来）
--    四、暂时用不到（框架自带，保留以免以后补表）
--    五、初始数据（只保留运行必需的，无任何联调测试数据）
--    六、上线自检
--
--  执行方式：
--      mysql -h <host> -u <user> -p <库名> < letmedoit_init.sql
--    或在客户端里整段执行。
--
--  幂等性：
--    * 建表统一 CREATE TABLE IF NOT EXISTS，重复执行不报错
--    * 数据类语句用固定主键插入，重复执行会主键冲突（属预期，重复导数据无意义）
--
--  不含任何测试数据：会员、任务、帮手、通知、上传记录、内容检测、协议同意记录、
--  反馈全部为空；后台只留 1 个 admin 账号（上线后立刻改密）。
--
--  ⚠️ 改表或改初始数据后，必须同时：
--     1) 在 docs/sql/updates/<日期>/ 下写增量脚本（给已有库）
--     2) 同步更新本文件（给新库）
--     3) 更新 docs/sql/README.md 里的「变更记录」表
--  规则详见 docs/sql/README.md
-- ============================================================================

SET NAMES utf8mb4;
SET time_zone = '+08:00';
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- ----------------------------------------------------------------------------
--  建库（已有库时跳过，按实际库名调整）
-- ----------------------------------------------------------------------------
-- CREATE DATABASE IF NOT EXISTS `letmedoit` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
-- USE `letmedoit`;

-- ============================================================================
--  表清单总览
-- ----------------------------------------------------------------------------
--  区  | 表名                          | 用途                                   | 状态
--  ----+-------------------------------+----------------------------------------+--------
--  一  | t_wx_member                   | 小程序会员                             | 必需
--  一  | t_helper                      | 帮手关系                               | 必需
--  一  | t_helper_request              | 帮手申请                               | 必需
--  一  | t_task                       | 任务主表                               | 必需
--  一  | t_task_participant            | 任务参与者                             | 必需
--  一  | t_task_event                  | 任务事件时间线                         | 必需
--  一  | t_task_notice                 | 站内服务通知                           | 必需
--  一  | t_file                        | 文件上传记录                           | 必需
--  一  | t_content_check               | 内容安全检测记录                       | 必需
--  一  | t_app_agreement               | 用户协议与隐私政策                     | 必需
--  一  | t_app_agreement_record        | 协议同意记录（举证用）                 | 必需
--  一  | t_app_feedback                | 问题与反馈（小程序提交）               | 必需
--  一  | t_app_version                 | 小程序版本（当前对外版本）             | 必需
--  一  | t_dict / t_dict_data          | 数据字典                               | 必需
--  ----+-------------------------------+----------------------------------------+--------
--  二  | t_smart_job                   | 定时任务配置                           | 必需
--  二  | t_smart_job_log               | 定时任务执行记录                       | 必需
--  二  | t_config                      | 系统配置                               | 必需
--  二  | t_login_log                   | 登录日志                               | 必需
--  ----+-------------------------------+----------------------------------------+--------
--  三  | t_employee                    | 后台账号                               | 后台
--  三  | t_department / t_position     | 部门 / 职务                            | 后台
--  三  | t_role / t_role_employee      | 角色 / 角色员工                        | 后台
--  三  | t_role_menu / t_role_data_scope| 角色菜单 / 数据范围                   | 后台
--  三  | t_menu                        | 后台菜单树                             | 后台
--  三  | t_login_fail                  | 登录失败锁定                           | 后台
--  三  | t_operate_log                 | 操作日志                               | 后台
--  三  | t_data_tracer                 | 单据留痕                               | 后台
--  三  | t_password_log                | 改密记录                               | 后台
--  三  | t_table_column                | 表格自定义列                           | 后台
--  三  | t_notice / t_notice_type      | 公告 / 公告类型                        | 后台
--  三  | t_notice_view_record          | 公告查看记录                           | 后台
--  三  | t_notice_visible_range        | 公告可见范围                           | 后台
--  三  | t_message                     | 站内信                                 | 后台
--  三  | t_mail_template               | 邮件模板                               | 后台
--  三  | t_reload_item / t_reload_result| 热加载                                | 后台
--  三  | t_heart_beat_record           | 服务心跳                               | 后台
--  三  | t_serial_number / _record     | 单号生成器                             | 后台
--  ----+-------------------------------+----------------------------------------+--------
--  四  | t_wx_order / t_wx_pay_notify_log | 订单 / 支付回调                     | 暂未使用
--  四  | t_code_generator_config       | 代码生成器配置                         | 暂未使用
-- ============================================================================

-- ============================================================================
--  一、sa-app 小程序运行必需
--  缺任何一张表，小程序接口都会报错。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- t_wx_member —— 小程序会员（openid/昵称/头像/邀请码）
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_wx_member` (
  `member_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '会员ID',
  `open_id` varchar(64) NOT NULL COMMENT '小程序 openid（当前appid下唯一）',
  `union_id` varchar(64) DEFAULT NULL COMMENT '开放平台 unionid（多端打通用）',
  `nickname` varchar(64) DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(500) DEFAULT NULL COMMENT '头像URL',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号（微信授权获取，可信）',
  `invite_code` varchar(8) DEFAULT NULL COMMENT '邀请码（6位，加帮手用）',
  `gender` tinyint(4) NOT NULL DEFAULT 0 COMMENT '性别 0未知 1男 2女',
  `disabled_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否禁用 0否 1是',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `last_login_time` datetime DEFAULT NULL COMMENT '最后登录时间',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`member_id`),
  UNIQUE KEY `uk_open_id` (`open_id`),
  UNIQUE KEY `uk_invite_code` (`invite_code`),
  KEY `idx_union_id` (`union_id`),
  KEY `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='微信小程序会员';

-- ----------------------------------------------------------------------------
-- t_helper —— 帮手关系，双向双写各一行
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_helper` (
  `helper_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `member_id` bigint(20) unsigned NOT NULL COMMENT '归属会员ID',
  `helper_member_id` bigint(20) unsigned NOT NULL COMMENT '帮手会员ID',
  `remark` varchar(64) DEFAULT NULL COMMENT '备注名（覆盖对方昵称展示）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`helper_id`),
  UNIQUE KEY `uk_member_helper` (`member_id`,`helper_member_id`),
  KEY `idx_helper_member` (`helper_member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='帮手关系';

-- ----------------------------------------------------------------------------
-- t_helper_request —— 帮手申请
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_helper_request` (
  `request_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `from_member_id` bigint(20) unsigned NOT NULL COMMENT '发起人会员ID',
  `to_member_id` bigint(20) unsigned NOT NULL COMMENT '接收人会员ID',
  `apply_message` varchar(100) DEFAULT NULL COMMENT '附言',
  `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '状态 0待处理 1已同意 2已拒绝',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`request_id`),
  KEY `idx_to_status` (`to_member_id`,`status`),
  KEY `idx_from_status` (`from_member_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='帮手申请';

-- ----------------------------------------------------------------------------
-- t_content_check —— 内容安全检测记录（审核要求：UGC 文本与图片必须过微信检测）
--   biz_type=text 走同步 msgSecCheck；图片走异步 mediaCheckAsync，
--   trace_id 用于和消息推送回来的结果配对
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- t_app_agreement / t_app_agreement_record —— 用户协议与隐私政策（后台可配置）
--   正文存表里，运营者改完立刻生效；同意动作留痕用于举证
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_app_agreement` (
  `agreement_id`   bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type`           varchar(20)  NOT NULL COMMENT '类型 user用户协议 privacy隐私政策',
  `title`          varchar(100) NOT NULL COMMENT '标题',
  `version`        varchar(20)  NOT NULL COMMENT '版本号，如 1.0.0',
  `content`        mediumtext   NOT NULL COMMENT '正文，纯文本（# 开头为标题行）',
  `effective_time` datetime     NOT NULL COMMENT '生效时间',
  `enabled_flag`   tinyint(1)   NOT NULL DEFAULT 1 COMMENT '是否启用 1启用 0停用',
  `create_time`    datetime     NOT NULL COMMENT '创建时间',
  `update_time`    datetime     NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`agreement_id`),
  KEY `idx_type_enabled` (`type`, `enabled_flag`, `effective_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户协议与隐私政策';

CREATE TABLE IF NOT EXISTS `t_app_agreement_record` (
  `record_id`      bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `member_id`      bigint(20) unsigned NOT NULL COMMENT '会员ID',
  `agreement_type` varchar(20)  NOT NULL COMMENT '协议类型 user/privacy',
  `version`        varchar(20)  NOT NULL COMMENT '同意的版本号',
  `agree_time`     datetime     NOT NULL COMMENT '同意时间',
  `ip`             varchar(64)  DEFAULT NULL COMMENT '同意时的IP',
  `user_agent`     varchar(255) DEFAULT NULL COMMENT '同意时的客户端标识',
  `create_time`    datetime     NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`record_id`),
  UNIQUE KEY `uk_member_type_version` (`member_id`, `agreement_type`, `version`),
  KEY `idx_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户协议同意记录';

-- ----------------------------------------------------------------------------
-- t_app_feedback —— 问题与反馈（小程序提交，后台处理）
--   类型 1功能建议 2使用问题 3内容违规 4其他；图片一列 JSON，最多 3 张
--   状态 0待处理 1处理中 2已解决 3已关闭，reply_* 三个字段给后台客服台
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- t_app_version —— 小程序版本
--   小程序里所有版本文案（「我的」页脚、关于弹窗）都读 /api/version/current，
--   代码里不再写死版本号。同端只应有一行 current_flag = 1。
--   force_update_flag / min_base_lib 是「强制更新」预留列，本期前端不读。
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- t_task —— 任务主表（含附图、编辑次数、到点通知开关）
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_task` (
  `task_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '任务ID',
  `title` varchar(60) NOT NULL COMMENT '任务标题',
  `description` varchar(500) DEFAULT NULL COMMENT '交代内容',
  `images` varchar(1000) DEFAULT NULL COMMENT '附图，JSON 数组字符串，最多 6 张公网 URL',
  `creator_id` bigint(20) unsigned NOT NULL COMMENT '委托人会员ID',
  `completion_mode` tinyint(4) NOT NULL DEFAULT 2 COMMENT '完成条件 1任一人完成 2全员完成',
  `status` tinyint(4) NOT NULL DEFAULT 1 COMMENT '聚合状态 0预约中 1待接受 2进行中 3已完成 4已拒绝 5已撤回',
  `start_time` datetime DEFAULT NULL COMMENT '定时生效时间（为空立即生效）',
  `start_notify_flag` tinyint(1) NOT NULL DEFAULT 1 COMMENT '开始时间点到点是否通知参与者 0否 1是',
  `deadline` datetime NOT NULL COMMENT '截止时间',
  `remind_minutes` int(11) NOT NULL DEFAULT 0 COMMENT '提前提醒分钟数 0不提醒',
  `remind_time` datetime DEFAULT NULL COMMENT '下次提醒时间（定时任务扫描用）',
  `edit_count` int(11) NOT NULL DEFAULT 0 COMMENT '编辑次数（进行中只允许改一次）',
  `last_remind_time` datetime DEFAULT NULL COMMENT '最后一次催办时间（限频用）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`task_id`),
  KEY `idx_creator_status` (`creator_id`,`status`),
  KEY `idx_status_deadline` (`status`,`deadline`),
  KEY `idx_remind_time` (`remind_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='任务';

-- ----------------------------------------------------------------------------
-- t_task_participant —— 任务参与者，一人一格
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_task_participant` (
  `participant_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` bigint(20) unsigned NOT NULL COMMENT '任务ID',
  `member_id` bigint(20) unsigned NOT NULL COMMENT '参与者会员ID',
  `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '参与状态 0待接受 1已接受 2已完成 3已拒绝 4已跳过',
  `complete_time` datetime DEFAULT NULL COMMENT '完成时间',
  `complete_remark` varchar(500) DEFAULT NULL COMMENT '完成备注',
  `complete_images` varchar(2000) DEFAULT NULL COMMENT '凭证图片URL，JSON数组字符串，最多3张',
  `reject_reason` varchar(200) DEFAULT NULL COMMENT '拒绝理由',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`participant_id`),
  UNIQUE KEY `uk_task_member` (`task_id`,`member_id`),
  KEY `idx_member_status` (`member_id`,`status`),
  KEY `idx_task_status` (`task_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='任务参与者';

-- ----------------------------------------------------------------------------
-- t_task_event —— 任务事件，详情页时间线
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_task_event` (
  `event_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` bigint(20) unsigned NOT NULL COMMENT '任务ID',
  `actor_id` bigint(20) unsigned DEFAULT NULL COMMENT '操作人会员ID（系统事件为空）',
  `event_type` tinyint(4) NOT NULL COMMENT '事件类型 1创建 2邀请 3接受 4拒绝 5完成 6撤回 7催办 8定时生效 9跳过',
  `content` varchar(255) NOT NULL COMMENT '事件描述',
  `create_time` datetime NOT NULL COMMENT '发生时间',
  PRIMARY KEY (`event_id`),
  KEY `idx_task_time` (`task_id`,`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='任务事件';

-- ----------------------------------------------------------------------------
-- t_task_notice —— 服务通知，站内消息中心
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_task_notice` (
  `notice_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `member_id` bigint(20) unsigned NOT NULL COMMENT '收件人会员ID',
  `task_id` bigint(20) unsigned DEFAULT NULL COMMENT '关联任务ID',
  `template_key` varchar(32) NOT NULL COMMENT '模板标识 TASK_ASSIGNED/TASK_REMIND/TASK_COMPLETED/TASK_ALL_DONE',
  `title` varchar(64) NOT NULL COMMENT '通知标题',
  `fields_json` varchar(2000) NOT NULL COMMENT '卡片键值对，JSON数组 [{label,value}]',
  `read_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已读 0未读 1已读',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`notice_id`),
  KEY `idx_member_read` (`member_id`,`read_flag`,`create_time`),
  KEY `idx_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='服务通知';

-- ----------------------------------------------------------------------------
-- t_file —— 文件上传记录，头像与任务图共用
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_file` (
  `file_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `folder_type` tinyint(3) unsigned NOT NULL COMMENT '文件夹类型',
  `file_name` varchar(100) DEFAULT NULL COMMENT '文件名称',
  `file_size` int(11) DEFAULT NULL COMMENT '文件大小',
  `file_key` varchar(200) NOT NULL COMMENT '文件key，用于文件下载',
  `file_type` varchar(50) NOT NULL COMMENT '文件类型',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人，即上传人',
  `creator_user_type` int(11) DEFAULT NULL COMMENT '创建人用户类型',
  `creator_name` varchar(100) DEFAULT NULL COMMENT '创建人姓名',
  `update_time` datetime DEFAULT current_timestamp() COMMENT '上次更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`file_id`) USING BTREE,
  UNIQUE KEY `uk_file_key` (`file_key`) USING BTREE,
  KEY `module_id_module_type` (`folder_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='文件';

-- ----------------------------------------------------------------------------
-- t_dict —— 数据字典主表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_dict` (
  `dict_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '字典id',
  `dict_name` varchar(500) NOT NULL COMMENT '字典名字',
  `dict_code` varchar(500) NOT NULL COMMENT '字典编码',
  `remark` varchar(1000) DEFAULT NULL COMMENT '字典备注',
  `disabled_flag` tinyint(4) NOT NULL DEFAULT 0 COMMENT '禁用状态',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`dict_id`),
  UNIQUE KEY `unique_code` (`dict_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='字典表';

-- ----------------------------------------------------------------------------
-- t_dict_data —— 字典项，状态文案来源
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_dict_data` (
  `dict_data_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '字典数据id',
  `dict_id` bigint(20) NOT NULL COMMENT '字典id',
  `data_value` varchar(500) NOT NULL COMMENT '字典项值',
  `data_label` varchar(500) NOT NULL COMMENT '字典项显示名称',
  `data_style` varchar(500) DEFAULT NULL COMMENT '字典项样式',
  `remark` varchar(1000) DEFAULT NULL COMMENT '备注',
  `sort_order` int(11) NOT NULL COMMENT '排序（越大越靠前）',
  `disabled_flag` tinyint(4) NOT NULL DEFAULT 0 COMMENT '禁用状态',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`dict_data_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='字典数据表';

-- ============================================================================
--  二、sa-base 通用能力
--  框架底座运行时直接读写的表。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- t_smart_job —— 定时任务配置，TaskScheduleJob 注册于此
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_smart_job` (
  `job_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '任务id',
  `job_name` varchar(50) NOT NULL COMMENT '任务名称',
  `job_class` varchar(200) NOT NULL COMMENT '任务执行类',
  `trigger_type` varchar(30) NOT NULL COMMENT '触发类型',
  `trigger_value` varchar(200) NOT NULL COMMENT '触发配置',
  `enabled_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否开启',
  `param` varchar(1000) DEFAULT NULL COMMENT '参数',
  `last_execute_time` datetime DEFAULT NULL COMMENT '最后一次执行时间',
  `last_execute_log_id` int(11) DEFAULT NULL COMMENT '最后一次执行记录id',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '描述',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '删除状态',
  `update_name` varchar(50) NOT NULL COMMENT '更新人',
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`job_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务配置 @listen';

-- ----------------------------------------------------------------------------
-- t_smart_job_log —— 定时任务执行记录，SmartJobExecutor 写入
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_smart_job_log` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `job_id` int(11) NOT NULL COMMENT '任务id',
  `job_name` varchar(100) NOT NULL COMMENT '任务名称',
  `param` varchar(2000) DEFAULT NULL COMMENT '执行参数',
  `success_flag` tinyint(1) NOT NULL COMMENT '是否成功',
  `execute_start_time` datetime NOT NULL COMMENT '执行开始时间',
  `execute_time_millis` int(11) DEFAULT NULL COMMENT '执行时长',
  `execute_end_time` datetime DEFAULT NULL COMMENT '执行结束时间',
  `execute_result` varchar(2000) DEFAULT NULL,
  `ip` varchar(50) NOT NULL COMMENT 'ip',
  `process_id` varchar(50) NOT NULL COMMENT '进程id',
  `program_path` varchar(255) NOT NULL COMMENT '程序目录',
  `create_name` varchar(100) NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`log_id`) USING BTREE,
  KEY `idx_job_id` (`job_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务-执行记录 @listen';

-- ----------------------------------------------------------------------------
-- t_config —— 系统配置，后台安全策略（密码复杂度/上传大小）
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_config` (
  `config_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `config_name` varchar(255) NOT NULL COMMENT '参数名字',
  `config_key` varchar(255) NOT NULL COMMENT '参数key',
  `config_value` text NOT NULL,
  `remark` varchar(255) DEFAULT NULL,
  `update_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '上次修改时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`config_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统配置';

-- ----------------------------------------------------------------------------
-- t_login_log —— 登录日志，小程序每次登录写入
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_login_log` (
  `login_log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL COMMENT '用户id',
  `user_type` int(11) NOT NULL COMMENT '用户类型',
  `user_name` varchar(1000) NOT NULL COMMENT '用户名',
  `login_ip` varchar(1000) DEFAULT NULL COMMENT '用户ip',
  `login_ip_region` varchar(1000) DEFAULT NULL COMMENT '用户ip地区',
  `user_agent` text DEFAULT NULL COMMENT 'user-agent信息',
  `login_device` varchar(1000) DEFAULT NULL COMMENT '登录设备',
  `login_result` int(11) NOT NULL COMMENT '登录结果：0成功 1失败 2 退出',
  `remark` varchar(2000) DEFAULT NULL COMMENT '备注',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`login_log_id`) USING BTREE,
  KEY `customer_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户登录日志';

-- ============================================================================
--  三、后台管理（sa-admin）
--  后台登录与运营功能依赖。当前版本后台与小程序同库，保留完整能力。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- t_employee —— 后台账号
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_employee` (
  `employee_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `employee_uid` varchar(100) DEFAULT NULL COMMENT '员工uuid',
  `login_name` varchar(30) NOT NULL COMMENT '登录帐号',
  `login_pwd` varchar(100) NOT NULL COMMENT '登录密码',
  `actual_name` varchar(30) NOT NULL COMMENT '员工名称',
  `avatar` varchar(200) DEFAULT NULL,
  `gender` tinyint(1) NOT NULL DEFAULT 0 COMMENT '性别',
  `phone` varchar(15) DEFAULT NULL COMMENT '手机号码',
  `department_id` bigint(20) NOT NULL COMMENT '部门id',
  `position_id` bigint(20) DEFAULT NULL COMMENT '职务ID',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `disabled_flag` tinyint(3) unsigned NOT NULL COMMENT '是否被禁用 0否1是',
  `deleted_flag` tinyint(3) unsigned NOT NULL COMMENT '是否删除0否 1是',
  `administrator_flag` tinyint(4) NOT NULL DEFAULT 0 COMMENT '是否为超级管理员: 0 不是，1是',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`employee_id`) USING BTREE,
  UNIQUE KEY `employee_uid_index` (`employee_uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='员工表';

-- ----------------------------------------------------------------------------
-- t_department —— 部门
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_department` (
  `department_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '部门主键id',
  `department_name` varchar(50) NOT NULL COMMENT '部门名称',
  `manager_id` bigint(20) DEFAULT NULL COMMENT '部门负责人id',
  `parent_id` bigint(20) NOT NULL DEFAULT 0 COMMENT '部门的父级id',
  `sort` int(11) NOT NULL COMMENT '部门排序',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`department_id`) USING BTREE,
  KEY `parent_id` (`parent_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='部门';

-- ----------------------------------------------------------------------------
-- t_position —— 职务
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_position` (
  `position_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '职务ID',
  `position_name` varchar(200) NOT NULL COMMENT '职务名称',
  `position_level` varchar(200) DEFAULT NULL COMMENT '职级',
  `sort` int(11) DEFAULT 0 COMMENT '排序',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `deleted_flag` tinyint(1) DEFAULT 0,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`position_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='职务表';

-- ----------------------------------------------------------------------------
-- t_role —— 角色
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_role` (
  `role_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_name` varchar(20) NOT NULL COMMENT '角色名称',
  `role_code` varchar(500) DEFAULT NULL COMMENT '角色编码',
  `remark` varchar(255) DEFAULT NULL COMMENT '角色描述',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '创建时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`role_id`) USING BTREE,
  UNIQUE KEY `role_code_uni` (`role_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色表';

-- ----------------------------------------------------------------------------
-- t_role_employee —— 角色-员工关联
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_role_employee` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `employee_id` bigint(20) NOT NULL COMMENT '员工id',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_role_employee` (`role_id`,`employee_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色员工功能表';

-- ----------------------------------------------------------------------------
-- t_role_menu —— 角色-菜单关联
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_role_menu` (
  `role_menu_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `menu_id` bigint(20) NOT NULL COMMENT '菜单id',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`role_menu_id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE,
  KEY `idx_menu_id` (`menu_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色-菜单\n';

-- ----------------------------------------------------------------------------
-- t_role_data_scope —— 角色数据范围
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_role_data_scope` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `data_scope_type` int(11) NOT NULL COMMENT '数据范围类型',
  `view_type` int(11) NOT NULL COMMENT '数据可见范围类型',
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色的数据范围';

-- ----------------------------------------------------------------------------
-- t_menu —— 后台菜单树，后台左侧导航的唯一来源
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_menu` (
  `menu_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '菜单ID',
  `menu_name` varchar(200) NOT NULL COMMENT '菜单名称',
  `menu_type` int(11) NOT NULL COMMENT '类型',
  `parent_id` bigint(20) NOT NULL COMMENT '父菜单ID',
  `sort` int(11) DEFAULT NULL COMMENT '显示顺序',
  `path` varchar(255) DEFAULT NULL COMMENT '路由地址',
  `component` varchar(255) DEFAULT NULL COMMENT '组件路径',
  `perms_type` int(11) DEFAULT NULL COMMENT '权限类型',
  `api_perms` varchar(5000) DEFAULT NULL COMMENT '后端权限字符串',
  `web_perms` varchar(5000) DEFAULT NULL COMMENT '前端权限字符串',
  `icon` varchar(100) DEFAULT NULL COMMENT '菜单图标',
  `context_menu_id` bigint(20) DEFAULT NULL COMMENT '功能点关联菜单ID',
  `frame_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否为外链',
  `frame_url` text DEFAULT NULL COMMENT '外链地址',
  `cache_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否缓存',
  `visible_flag` tinyint(1) NOT NULL DEFAULT 1 COMMENT '显示状态',
  `disabled_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '禁用状态',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '删除状态',
  `create_user_id` bigint(20) NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_user_id` bigint(20) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`menu_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='菜单表';

-- ----------------------------------------------------------------------------
-- t_login_fail —— 登录失败计数，连续失败锁定
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_login_fail` (
  `login_fail_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `user_id` bigint(20) NOT NULL COMMENT '用户id',
  `user_type` int(11) NOT NULL COMMENT '用户类型',
  `login_name` varchar(1000) DEFAULT NULL COMMENT '登录名',
  `login_fail_count` int(11) DEFAULT NULL COMMENT '连续登录失败次数',
  `lock_flag` tinyint(4) DEFAULT 0 COMMENT '锁定状态:1锁定，0未锁定',
  `login_lock_begin_time` datetime DEFAULT NULL COMMENT '连续登录失败锁定开始时间',
  `create_time` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`login_fail_id`) USING BTREE,
  UNIQUE KEY `uid_and_utype` (`user_id`,`user_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='登录失败次数记录表';

-- ----------------------------------------------------------------------------
-- t_operate_log —— 后台操作日志
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_operate_log` (
  `operate_log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operate_user_id` bigint(20) NOT NULL COMMENT '用户id',
  `operate_user_type` int(11) NOT NULL COMMENT '用户类型',
  `operate_user_name` varchar(500) NOT NULL COMMENT '用户名称',
  `module` varchar(500) DEFAULT NULL COMMENT '操作模块',
  `content` text DEFAULT NULL COMMENT '操作内容',
  `url` text DEFAULT NULL COMMENT '请求路径',
  `method` text DEFAULT NULL COMMENT '请求方法',
  `param` text DEFAULT NULL COMMENT '请求参数',
  `response` text DEFAULT NULL COMMENT '返回结果',
  `ip` varchar(1000) DEFAULT NULL COMMENT '请求ip',
  `ip_region` varchar(1000) DEFAULT NULL COMMENT '请求ip地区',
  `user_agent` text DEFAULT NULL COMMENT '请求user-agent',
  `success_flag` tinyint(4) DEFAULT NULL COMMENT '请求结果 0失败 1成功',
  `fail_reason` longtext DEFAULT NULL COMMENT '失败原因',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`operate_log_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='操作记录';

-- ----------------------------------------------------------------------------
-- t_data_tracer —— 单据操作留痕
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_data_tracer` (
  `data_tracer_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `data_id` bigint(20) NOT NULL COMMENT '各种单据的id',
  `type` int(11) NOT NULL COMMENT '单据类型',
  `content` text DEFAULT NULL COMMENT '操作内容',
  `diff_old` text DEFAULT NULL COMMENT '差异：旧的数据',
  `diff_new` text DEFAULT NULL COMMENT '差异：新的数据',
  `extra_data` text DEFAULT NULL COMMENT '额外信息',
  `user_id` bigint(20) NOT NULL COMMENT '用户id',
  `user_type` int(11) NOT NULL COMMENT '用户类型：1 后管用户 ',
  `user_name` varchar(50) NOT NULL COMMENT '用户名称',
  `ip` varchar(50) DEFAULT NULL COMMENT 'ip',
  `ip_region` varchar(1000) DEFAULT NULL COMMENT 'ip地区',
  `user_agent` varchar(2000) DEFAULT NULL COMMENT '用户ua',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`data_tracer_id`) USING BTREE,
  KEY `order_id_order_type` (`data_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='各种单据操作记录';

-- ----------------------------------------------------------------------------
-- t_password_log —— 改密记录
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_password_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint(20) NOT NULL COMMENT '用户id',
  `user_type` tinyint(4) NOT NULL COMMENT '用户类型',
  `old_password` varchar(255) NOT NULL COMMENT '旧密码',
  `new_password` varchar(255) DEFAULT NULL COMMENT '新密码',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '创建时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `user_and_type_index` (`user_id`,`user_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='密码修改记录';

-- ----------------------------------------------------------------------------
-- t_table_column —— 表格自定义列
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_table_column` (
  `table_column_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户id',
  `user_type` int(11) NOT NULL COMMENT '用户类型',
  `table_id` int(11) NOT NULL COMMENT '表格id',
  `columns` text DEFAULT NULL COMMENT '具体的表格列，存入的json',
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`table_column_id`) USING BTREE,
  UNIQUE KEY `uni_employee_table` (`user_id`,`table_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='表格的自定义列存储';

-- ----------------------------------------------------------------------------
-- t_notice —— 站内公告
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_notice` (
  `notice_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `notice_type_id` bigint(20) NOT NULL COMMENT '类型1公告 2动态',
  `title` varchar(200) NOT NULL COMMENT '标题',
  `all_visible_flag` tinyint(1) NOT NULL COMMENT '是否全部可见',
  `scheduled_publish_flag` tinyint(1) NOT NULL COMMENT '是否定时发布',
  `publish_time` datetime NOT NULL COMMENT '发布时间',
  `content_text` text NOT NULL COMMENT '文本内容',
  `content_html` text NOT NULL COMMENT 'html内容',
  `attachment` varchar(1000) DEFAULT NULL COMMENT '附件',
  `page_view_count` int(11) NOT NULL DEFAULT 0 COMMENT '页面浏览量，传说中的pv',
  `user_view_count` int(11) NOT NULL DEFAULT 0 COMMENT '用户浏览量，传说中的uv',
  `source` varchar(1000) DEFAULT NULL COMMENT '来源',
  `author` varchar(1000) DEFAULT NULL COMMENT '作者',
  `document_number` varchar(1000) DEFAULT NULL COMMENT '文号，如：1024创新实验室发〔2022〕字第36号',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT 0,
  `create_user_id` bigint(20) DEFAULT NULL COMMENT '创建人',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`notice_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知';

-- ----------------------------------------------------------------------------
-- t_notice_type —— 公告类型
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_notice_type` (
  `notice_type_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '通知类型',
  `notice_type_name` varchar(1000) NOT NULL COMMENT '类型名称',
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`notice_type_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知类型';

-- ----------------------------------------------------------------------------
-- t_notice_view_record —— 公告查看记录
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_notice_view_record` (
  `notice_id` bigint(20) NOT NULL COMMENT '通知公告id',
  `employee_id` bigint(20) NOT NULL COMMENT '员工id',
  `page_view_count` int(11) DEFAULT 0 COMMENT '查看次数',
  `first_ip` varchar(255) DEFAULT NULL COMMENT '首次ip',
  `first_user_agent` varchar(1000) DEFAULT NULL COMMENT '首次用户设备等标识',
  `last_ip` varchar(255) DEFAULT NULL COMMENT '最后一次ip',
  `last_user_agent` varchar(1000) DEFAULT NULL COMMENT '最后一次用户设备等标识',
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`notice_id`,`employee_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知查看记录';

-- ----------------------------------------------------------------------------
-- t_notice_visible_range —— 公告可见范围
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_notice_visible_range` (
  `notice_id` bigint(20) NOT NULL COMMENT '资讯id',
  `data_type` tinyint(4) NOT NULL COMMENT '数据类型1员工 2部门',
  `data_id` bigint(20) NOT NULL COMMENT '员工or部门id',
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  UNIQUE KEY `uk_notice_data` (`notice_id`,`data_type`,`data_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知可见范围';

-- ----------------------------------------------------------------------------
-- t_message —— 站内信
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_message` (
  `message_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '消息id',
  `message_type` smallint(6) NOT NULL COMMENT '消息类型',
  `receiver_user_type` int(11) NOT NULL COMMENT '接收者用户类型',
  `receiver_user_id` bigint(20) NOT NULL COMMENT '接收者用户id',
  `data_id` varchar(500) DEFAULT '' COMMENT '相关数据id',
  `title` varchar(1000) NOT NULL COMMENT '标题',
  `content` text NOT NULL COMMENT '内容',
  `read_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已读',
  `read_time` datetime DEFAULT NULL COMMENT '已读时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`message_id`) USING BTREE,
  KEY `idx_msg` (`message_type`,`receiver_user_type`,`receiver_user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知消息';

-- ----------------------------------------------------------------------------
-- t_mail_template —— 邮件模板
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_mail_template` (
  `template_code` varchar(200) NOT NULL,
  `template_subject` varchar(100) NOT NULL COMMENT '模板名称',
  `template_content` longtext NOT NULL COMMENT '模板内容',
  `template_type` varchar(50) NOT NULL COMMENT '解析类型 string，freemarker',
  `disable_flag` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否禁用',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '创建时间',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`template_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='邮件模板';

-- ----------------------------------------------------------------------------
-- t_reload_item —— 热加载项
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_reload_item` (
  `tag` varchar(255) NOT NULL COMMENT '项名称',
  `args` varchar(255) DEFAULT NULL COMMENT '参数 可选',
  `identification` varchar(255) NOT NULL COMMENT '运行标识',
  `update_time` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`tag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='reload项目';

-- ----------------------------------------------------------------------------
-- t_reload_result —— 热加载结果
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_reload_result` (
  `tag` varchar(255) NOT NULL,
  `identification` varchar(255) NOT NULL COMMENT '运行标识',
  `args` varchar(255) DEFAULT NULL,
  `result` tinyint(3) unsigned NOT NULL COMMENT '是否成功 ',
  `exception` text DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='reload结果';

-- ----------------------------------------------------------------------------
-- t_heart_beat_record —— 服务心跳记录
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_heart_beat_record` (
  `heart_beat_record_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `project_path` varchar(100) NOT NULL COMMENT '项目名称',
  `server_ip` varchar(200) NOT NULL COMMENT '服务器ip',
  `process_no` int(11) NOT NULL COMMENT '进程号',
  `process_start_time` datetime NOT NULL COMMENT '进程开启时间',
  `heart_beat_time` datetime NOT NULL COMMENT '心跳时间',
  PRIMARY KEY (`heart_beat_record_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='公用服务 - 服务心跳';

-- ----------------------------------------------------------------------------
-- t_serial_number —— 单号生成器定义
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_serial_number` (
  `serial_number_id` int(11) NOT NULL,
  `business_name` varchar(50) NOT NULL COMMENT '业务名称',
  `format` varchar(50) DEFAULT NULL COMMENT '格式[yyyy]表示年,[mm]标识月,[dd]表示日,[nnn]表示三位数字',
  `rule_type` varchar(20) NOT NULL COMMENT '规则格式。none没有周期, year 年周期, month月周期, day日周期',
  `init_number` int(10) unsigned NOT NULL COMMENT '初始值',
  `step_random_range` int(10) unsigned NOT NULL COMMENT '步长随机数',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `last_number` bigint(20) DEFAULT NULL COMMENT '上次产生的单号, 默认为空',
  `last_time` datetime DEFAULT NULL COMMENT '上次产生的单号时间',
  `update_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `create_time` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`serial_number_id`) USING BTREE,
  UNIQUE KEY `key_name` (`business_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='单号生成器定义表';

-- ----------------------------------------------------------------------------
-- t_serial_number_record —— 单号生成记录
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_serial_number_record` (
  `serial_number_id` int(11) NOT NULL,
  `record_date` date NOT NULL COMMENT '记录日期',
  `last_number` bigint(20) NOT NULL DEFAULT 0 COMMENT '最后更新值',
  `last_time` datetime NOT NULL COMMENT '最后更新时间',
  `count` bigint(20) NOT NULL DEFAULT 0 COMMENT '更新次数',
  `update_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `create_time` datetime DEFAULT current_timestamp(),
  KEY `uk_generator` (`serial_number_id`,`record_date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='serial_number记录表';

-- ============================================================================
--  四、暂时用不到
--  建空表但当前版本不写入、不读取。功能启用时无需改脚本。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- t_wx_order —— 小程序订单
-- 暂未使用：微信支付未接入，当前版本仅免费使用
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_wx_order` (
  `order_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no` varchar(32) NOT NULL COMMENT '业务订单号（唯一）',
  `member_id` bigint(20) unsigned NOT NULL COMMENT '会员ID',
  `open_id` varchar(64) NOT NULL COMMENT '下单时的 openid',
  `title` varchar(128) NOT NULL COMMENT '商品标题',
  `description` varchar(255) DEFAULT NULL COMMENT '商品描述',
  `total_fee` bigint(20) NOT NULL COMMENT '订单金额（分）',
  `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '状态 0待支付 1已支付 2已关闭 3退款中 4已退款',
  `prepay_id` varchar(128) DEFAULT NULL COMMENT '微信预支付ID',
  `transaction_id` varchar(64) DEFAULT NULL COMMENT '微信支付交易号',
  `pay_time` datetime DEFAULT NULL COMMENT '支付时间',
  `expire_time` datetime DEFAULT NULL COMMENT '订单过期时间（默认2小时）',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  UNIQUE KEY `uk_transaction_id` (`transaction_id`),
  KEY `idx_member_id` (`member_id`),
  KEY `idx_status_create` (`status`,`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='小程序订单';

-- ----------------------------------------------------------------------------
-- t_wx_pay_notify_log —— 支付回调日志
-- 暂未使用：同上
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_wx_pay_notify_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `notify_id` varchar(64) NOT NULL COMMENT '微信回调通知ID（唯一，防重放）',
  `event_type` varchar(64) DEFAULT NULL COMMENT '事件类型 TRANSACTION.SUCCESS / REFUND.SUCCESS',
  `out_trade_no` varchar(32) DEFAULT NULL COMMENT '商户订单号',
  `transaction_id` varchar(64) DEFAULT NULL COMMENT '微信交易号',
  `verify_result` tinyint(1) NOT NULL DEFAULT 0 COMMENT '验签结果 0失败 1成功',
  `handle_result` tinyint(1) NOT NULL DEFAULT 0 COMMENT '处理结果 0失败 1成功',
  `raw_body` text DEFAULT NULL COMMENT '原始报文（脱敏后）',
  `error_msg` varchar(500) DEFAULT NULL COMMENT '异常信息',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notify_id` (`notify_id`),
  KEY `idx_out_trade_no` (`out_trade_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='微信支付回调日志';

-- ----------------------------------------------------------------------------
-- t_code_generator_config —— 代码生成器配置
-- 暂未使用：仅开发期使用，生产不需要
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_code_generator_config` (
  `table_name` varchar(255) NOT NULL COMMENT '表名',
  `basic` text DEFAULT NULL COMMENT '基础命名信息',
  `fields` text DEFAULT NULL COMMENT '字段列表',
  `insert_and_update` text DEFAULT NULL COMMENT '新建、修改',
  `delete_info` text DEFAULT NULL COMMENT '删除',
  `query_fields` text DEFAULT NULL COMMENT '查询',
  `table_fields` text DEFAULT NULL COMMENT '列表',
  `detail` text DEFAULT NULL COMMENT '详情',
  `create_time` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`table_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='代码生成器的每个表的配置';

-- ============================================================================
--  五、初始数据（去测试数据后仅保留这些，共 11 项）
-- ----------------------------------------------------------------------------
--  1. t_config        后台安全策略 2 条（密码复杂度、上传大小 30MB、登录失败锁定）
--  2. t_department    1 个「总部」，后台员工必须有归属部门
--  3. t_position      1 个「普通员工」
--  4. t_employee      1 个 admin 账号（超级管理员，密码沿用 SmartAdmin 默认 123456）
--  5. t_menu          96 条后台菜单（77 条框架菜单 + 让我做运营 19 条），后台导航的唯一来源，不可删
--  6. t_dict          6 本业务字典（任务 4 本 + 反馈 2 本）
--  7. t_dict_data     30 条字典项，小程序状态/类型文案从这张表读
--  8. t_smart_job     1 个定时作业（任务到点生效与到期提醒，每分钟）
--  9. t_notice_type   2 条公告类型（后台公告功能下拉用）
-- 10. t_app_agreement 用户协议 + 隐私政策正文（缺了登录会被拒）
-- 11. t_app_version   当前小程序版本（v1.0.0，与线上小程序包版本一致）
--
--  已清空的测试数据：
--    t_wx_member / t_helper / t_helper_request / t_task / t_task_participant
--    t_task_event / t_task_notice / t_file / t_content_check / t_app_agreement_record / t_app_feedback
--    t_wx_order / t_wx_pay_notify_log
--    t_employee(除 admin) / t_role / t_role_employee / t_role_menu / t_role_data_scope
--    t_notice(12) / t_message(4) / t_smart_job(示例任务 2 个) / t_dict(GOODS_PLACE 商品地区)
--    演示与框架遗留表（t_goods / t_category / t_oa_* / t_help_doc* / t_change_log / t_feedback）已整表删除，见 updates/2026-10-29/03_drop_demo_tables.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
--  1. 系统配置
-- ----------------------------------------------------------------------------
-- level3_protect_config 是后台「三级等保」安全策略，maxUploadFileSizeMb=30 同时约束
-- 小程序头像与任务图上传大小。缺这条记录时后台配置页读不到值，务必保留。
INSERT INTO `t_config` (`config_name`, `config_key`, `config_value`, `remark`, `create_time`, `update_time`) VALUES
('万能密码', 'super_password', '1024ok', '执行示例任务2', '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_config` (`config_name`, `config_key`, `config_value`, `remark`, `create_time`, `update_time`) VALUES
('三级等保', 'level3_protect_config', '{\n	\"fileDetectFlag\":true,\n	\"loginActiveTimeoutMinutes\":30,\n	\"loginFailLockMinutes\":30,\n	\"loginFailMaxTimes\":3,\n	\"maxUploadFileSizeMb\":30,\n	\"passwordComplexityEnabled\":true,\n	\"regularChangePasswordMonths\":3,\n	\"regularChangePasswordNotAllowRepeatTimes\":3,\n	\"twoFactorLoginEnabled\":false\n}', 'SmartJob Sample2 update', '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  2~4. 部门 / 职务 / 管理员账号
-- ----------------------------------------------------------------------------
-- admin 密码是 argon2id 哈希，对应 SmartAdmin 默认密码 123456。
-- 上线后第一件事：登录后台改密（或直接改成随机强密码）。
-- avatar 置空：原库里的头像是开发期上传的测试文件，正式环境对象存储里不存在。
-- administrator_flag=1 表示超级管理员，不受角色菜单限制。
INSERT INTO `t_department` (`department_id`, `department_name`, `manager_id`, `parent_id`, `sort`, `update_time`, `create_time`) VALUES
(1, '总部', NULL, 0, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_position` (`position_id`, `position_name`, `position_level`, `sort`, `remark`, `deleted_flag`, `create_time`, `update_time`) VALUES
(1, '普通员工', 1, 1, NULL, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_employee` (`employee_uid`, `login_name`, `login_pwd`, `actual_name`, `avatar`, `gender`, `phone`, `department_id`, `position_id`, `email`, `disabled_flag`, `deleted_flag`, `administrator_flag`, `remark`, `update_time`, `create_time`) VALUES
('cf1e361fd46741f5b2a09335cef50db8', 'admin', '$argon2id$v=19$m=16384,t=2,p=1$d9yQEAhck+haKxP2ZtXocg$NEnw3D2Ly8UbYpy2odATLA4ZflZ1FKJjWCuOGrVE4PM', '管理员', NULL, 0, '13500000000', 1, 1, NULL, 0, 0, 1, NULL, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  5. 后台菜单（96 条，整棵树，勿手工删减；其中让我做运营 19 条见下 5.1，演示与文档中心菜单已下线）
-- ----------------------------------------------------------------------------
-- 后台左侧导航、按钮权限（api_perms / web_perms）全部来自这张表。
-- 删了对应菜单，后台页面会 404 或按钮消失。
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(26, '菜单管理', 2, 50, 1, '/menu/list', '/system/menu/menu-list.vue', NULL, NULL, NULL, 'CopyOutlined', NULL, 0, NULL, 1, 1, 0, 0, 2, '2021-08-09 15:04:35', 1, '2023-12-01 19:39:03'),
(40, '删除', 3, 26, NULL, NULL, NULL, 1, 'system:menu:batchDelete', 'system:menu:batchDelete', NULL, 26, 0, NULL, 0, 1, 0, 0, 1, '2021-08-12 09:45:56', 1, '2023-10-07 18:15:50'),
(45, '组织架构', 1, 0, 3, '/organization', NULL, NULL, NULL, NULL, 'UserSwitchOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2021-08-12 16:13:27', 1, '2024-07-02 19:27:44'),
(46, '员工管理', 2, 45, 3, '/organization/employee', '/system/employee/index.vue', NULL, NULL, NULL, 'AuditOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2021-08-12 16:21:50', 1, '2024-07-02 20:15:23');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(50, '系统设置', 1, 0, 6, '/setting', NULL, NULL, NULL, NULL, 'SettingOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2021-08-13 16:41:33', 1, '2023-12-01 19:38:03'),
(76, '角色管理', 2, 45, 4, '/organization/role', '/system/role/index.vue', NULL, NULL, NULL, 'SlidersOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2021-08-26 10:31:00', 1, '2024-07-02 20:15:28');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(81, '用户操作记录', 2, 213, 6, '/support/operate-log/operate-log-list', '/support/operate-log/operate-log-list.vue', NULL, NULL, NULL, 'VideoCameraOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-20 12:37:24', 44, '2024-08-13 14:34:10'),
(86, '添加部门', 3, 46, 1, NULL, NULL, 1, 'system:department:add', 'system:department:add', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-26 23:33:37', 1, '2023-10-07 18:26:35'),
(87, '修改部门', 3, 46, 2, NULL, NULL, 1, 'system:department:update', 'system:department:update', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-26 23:34:11', 1, '2023-10-07 18:26:44'),
(88, '删除部门', 3, 46, 3, NULL, NULL, 1, 'system:department:delete', 'system:department:delete', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-26 23:34:49', 1, '2023-10-07 18:26:49');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(91, '添加员工', 3, 46, NULL, NULL, NULL, 1, 'system:employee:add', 'system:employee:add', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:11:38', 1, '2023-10-07 18:27:46'),
(92, '编辑员工', 3, 46, NULL, NULL, NULL, 1, 'system:employee:update', 'system:employee:update', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:12:10', 1, '2023-10-07 18:27:49'),
(93, '禁用启用员工', 3, 46, NULL, NULL, NULL, 1, 'system:employee:disabled', 'system:employee:disabled', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:12:37', 1, '2023-10-07 18:27:53'),
(94, '调整员工部门', 3, 46, NULL, NULL, NULL, 1, 'system:employee:department:update', 'system:employee:department:update', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:12:59', 1, '2023-10-07 18:27:34'),
(95, '重置密码', 3, 46, NULL, NULL, NULL, 1, 'system:employee:password:reset', 'system:employee:password:reset', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:13:30', 1, '2023-10-07 18:27:57');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(96, '删除员工', 3, 46, NULL, NULL, NULL, 1, 'system:employee:delete', 'system:employee:delete', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:14:08', 1, '2023-10-07 18:28:01'),
(97, '添加角色', 3, 76, NULL, NULL, NULL, 1, 'system:role:add', 'system:role:add', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:34:00', 1, '2023-10-07 18:42:31'),
(98, '删除角色', 3, 76, NULL, NULL, NULL, 1, 'system:role:delete', 'system:role:delete', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:34:19', 1, '2023-10-07 18:42:35'),
(99, '编辑角色', 3, 76, NULL, NULL, NULL, 1, 'system:role:update', 'system:role:update', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:34:55', 1, '2023-10-07 18:42:44'),
(100, '更新数据范围', 3, 76, NULL, NULL, NULL, 1, 'system:role:dataScope:update', 'system:role:dataScope:update', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:37:03', 1, '2023-10-07 18:41:49');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(101, '批量移除员工', 3, 76, NULL, NULL, NULL, 1, 'system:role:employee:batch:delete', 'system:role:employee:batch:delete', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:39:05', 1, '2023-10-07 18:43:32'),
(102, '移除员工', 3, 76, NULL, NULL, NULL, 1, 'system:role:employee:delete', 'system:role:employee:delete', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:39:21', 1, '2023-10-07 18:43:37'),
(103, '添加员工', 3, 76, NULL, NULL, NULL, 1, 'system:role:employee:add', 'system:role:employee:add', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:39:38', 1, '2023-10-07 18:44:05'),
(104, '修改权限', 3, 76, NULL, NULL, NULL, 1, 'system:role:menu:update', 'system:role:menu:update', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:41:55', 1, '2023-10-07 18:44:11'),
(105, '添加', 3, 26, NULL, NULL, NULL, 1, 'system:menu:add', 'system:menu:add', NULL, 26, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:44:37', 1, '2023-10-07 17:35:35');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(106, '编辑', 3, 26, NULL, NULL, NULL, 1, 'system:menu:update', 'system:menu:update', NULL, 26, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 00:44:59', 1, '2023-10-07 17:35:48'),
(109, '参数配置', 2, 50, 3, '/config/config-list', '/support/config/config-list.vue', NULL, NULL, NULL, 'AntDesignOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 13:34:41', 1, '2022-06-23 16:24:16'),
(110, '数据字典', 2, 50, 4, '/setting/dict', '/support/dict/index.vue', NULL, NULL, NULL, 'BarcodeOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-05-27 17:53:00', 1, '2022-05-27 18:09:14'),
(111, '监控服务', 1, 0, 100, '/monitor', NULL, NULL, NULL, NULL, 'BarChartOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-06-17 11:13:23', 1, '2023-11-28 17:43:56');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(114, '运维工具', 1, 0, 200, NULL, NULL, NULL, NULL, NULL, 'NodeCollapseOutlined', NULL, 0, NULL, 0, 1, 0, 1, 1, '2022-06-20 10:09:16', 1, '2023-12-01 19:36:18'),
(117, 'Reload', 2, 50, 12, '/hook', '/support/reload/reload-list.vue', NULL, NULL, NULL, 'ReloadOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-06-20 10:16:49', 1, '2023-12-01 19:39:17'),
(122, '数据库监控', 2, 111, 4, '/support/druid/index', NULL, NULL, NULL, NULL, 'ConsoleSqlOutlined', NULL, 1, 'http://localhost:1024/druid', 1, 1, 0, 0, 1, '2022-06-20 14:49:33', 1, '2023-02-16 19:15:58'),
(130, '单号管理', 2, 50, 6, '/support/serial-number/serial-number-list', '/support/serial-number/serial-number-list.vue', NULL, NULL, NULL, 'NumberOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-06-24 14:45:22', 1, '2022-06-28 16:23:41');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(133, '缓存管理', 2, 50, 11, '/support/cache/cache-list', '/support/cache/cache-list.vue', NULL, NULL, NULL, 'BorderInnerOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-06-24 18:52:25', 1, '2023-12-01 19:39:13'),
(143, '登录登出记录', 2, 213, 5, '/support/login-log/login-log-list', '/support/login-log/login-log-list.vue', NULL, NULL, NULL, 'LoginOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-06-28 15:01:38', 44, '2024-08-13 14:33:49');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(151, '代码生成', 2, 0, 600, '/support/code-generator', '/support/code-generator/code-generator-list.vue', NULL, NULL, NULL, 'CoffeeOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-09-21 18:25:05', 1, '2022-10-22 11:27:58'),
(153, '清除缓存', 3, 133, NULL, NULL, NULL, 1, 'support:cache:delete', 'support:cache:delete', NULL, 133, 0, NULL, 0, 1, 1, 0, 1, '2022-10-15 22:45:13', 1, '2023-10-07 16:22:29'),
(154, '获取缓存key', 3, 133, NULL, NULL, NULL, 1, 'support:cache:keys', 'support:cache:keys', NULL, 133, 0, NULL, 0, 1, 1, 0, 1, '2022-10-15 22:45:48', 1, '2023-10-07 16:22:35'),
(156, '查看结果', 3, 117, NULL, NULL, NULL, 1, 'support:reload:result', 'support:reload:result', NULL, 117, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:17:23', 1, '2023-10-07 14:31:47');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(157, '单号生成', 3, 130, NULL, NULL, NULL, 1, 'support:serialNumber:generate', 'support:serialNumber:generate', NULL, 130, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:21:06', 1, '2023-10-07 18:22:46'),
(158, '生成记录', 3, 130, NULL, NULL, NULL, 1, 'support:serialNumber:record', 'support:serialNumber:record', NULL, 130, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:21:34', 1, '2023-10-07 18:22:55'),
(159, '查询', 3, 110, NULL, NULL, NULL, 1, 'support:dict:query', 'support:dict:query', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:23:51', 1, '2025-04-08 19:42:25'),
(160, '添加', 3, 110, NULL, NULL, NULL, 1, 'support:dict:add', 'support:dict:add', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:24:05', 1, '2025-04-08 19:43:02'),
(161, '更新', 3, 110, NULL, NULL, NULL, 1, 'support:dict:update', 'support:dict:update', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:24:34', 1, '2025-04-08 19:43:34');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(162, '删除', 3, 110, NULL, NULL, NULL, 1, 'support:dict:delete', 'support:dict:delete', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:24:55', 1, '2025-04-08 19:43:52'),
(163, '新建', 3, 109, NULL, NULL, NULL, 1, 'support:config:add', 'support:config:add', NULL, 109, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:26:56', 1, '2023-10-07 18:16:17'),
(164, '编辑', 3, 109, NULL, NULL, NULL, 1, 'support:config:update', 'support:config:update', NULL, 109, 0, NULL, 0, 1, 0, 0, 1, '2022-10-15 23:27:07', 1, '2023-10-07 18:16:24');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(193, '文件管理', 2, 50, 20, '/support/file/file-list', '/support/file/file-list.vue', NULL, NULL, NULL, 'FolderOpenOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-21 11:26:11', 1, '2022-10-22 11:29:22');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(199, '查询', 3, 109, NULL, NULL, NULL, 1, 'support:config:query', 'support:config:query', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-21 20:45:14', 1, '2023-10-07 18:16:27');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(200, '查询', 3, 193, NULL, NULL, NULL, 1, 'support:file:query', 'support:file:query', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-21 20:47:23', 1, '2023-10-07 18:24:43'),
(203, '查询', 3, 143, NULL, NULL, NULL, 1, 'support:loginLog:query', 'support:loginLog:query', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-21 21:05:11', 1, '2023-10-07 14:27:23'),
(204, '查询', 3, 81, NULL, NULL, NULL, 1, 'support:operateLog:query', 'support:operateLog:query', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-22 10:33:31', 1, '2023-10-07 14:27:56');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(205, '详情', 3, 81, NULL, NULL, NULL, 1, 'support:operateLog:detail', 'support:operateLog:detail', NULL, NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-22 10:33:49', 1, '2023-10-07 14:28:04'),
(206, '心跳监控', 2, 111, 1, '/support/heart-beat/heart-beat-list', '/support/heart-beat/heart-beat-list.vue', 1, NULL, NULL, 'FallOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2022-10-22 10:47:03', 1, '2022-10-22 18:32:52'),
(212, '查询', 3, 117, NULL, NULL, NULL, 1, 'support:reload:query', 'support:reload:query', NULL, NULL, 0, NULL, 1, 1, 1, 0, 1, '2023-10-07 14:31:36', NULL, '2023-10-07 14:31:36'),
(213, '网络安全', 1, 0, 5, NULL, NULL, 1, NULL, NULL, 'SafetyCertificateOutlined', NULL, 0, NULL, 1, 1, 0, 0, 1, '2023-10-17 19:03:08', 1, '2023-12-01 19:38:00');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(214, '登录失败锁定', 2, 213, 4, '/support/login-fail', '/support/login-fail/login-fail-list.vue', 1, NULL, NULL, 'LockOutlined', NULL, 0, NULL, 1, 1, 0, 0, 1, '2023-10-17 19:04:24', 44, '2024-08-13 14:16:26'),
(215, '接口加解密', 2, 213, 2, '/support/api-encrypt', '/support/api-encrypt/api-encrypt-index.vue', 1, NULL, NULL, 'CodepenCircleOutlined', NULL, 0, NULL, 1, 1, 0, 0, 1, '2023-10-24 11:49:28', 44, '2024-08-13 12:00:14'),
(218, '文档中心', 1, 0, 4, NULL, NULL, 1, NULL, NULL, 'FileSearchOutlined', NULL, 0, NULL, 1, 1, 0, 0, 1, '2023-12-01 19:37:28', 1, '2023-12-01 19:37:51');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(219, '部门管理', 2, 45, 1, '/organization/department', '/system/department/department-list.vue', 1, NULL, NULL, 'ApartmentOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2024-06-22 16:40:21', 1, '2024-07-02 20:15:17'),
(221, '定时任务', 2, 50, 25, '/job/list', '/support/job/job-list.vue', 1, NULL, NULL, 'AppstoreOutlined', NULL, 0, NULL, 1, 1, 0, 0, 2, '2024-06-25 17:57:40', 2, '2024-06-25 19:49:21'),
(228, '职务管理', 2, 45, 2, '/organization/position', '/system/position/position-list.vue', 1, NULL, NULL, 'ApartmentOutlined', NULL, 0, NULL, 1, 1, 0, 0, 1, '2024-06-29 11:11:09', 1, '2024-07-02 20:15:11'),
(229, '查询任务', 3, 221, NULL, NULL, NULL, 1, 'support:job:query', 'support:job:query', NULL, 221, 0, NULL, 1, 1, 0, 0, 2, '2024-06-29 11:14:15', 2, '2024-06-29 11:15:00'),
(230, '更新任务', 3, 221, NULL, NULL, NULL, 1, 'support:job:update', 'support:job:update', NULL, 221, 0, NULL, 1, 1, 0, 0, 2, '2024-06-29 11:15:40', NULL, '2024-06-29 11:15:40');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(231, '执行任务', 3, 221, NULL, NULL, NULL, 1, 'support:job:execute', 'support:job:execute', NULL, 221, 0, NULL, 1, 1, 0, 0, 2, '2024-06-29 11:16:03', NULL, '2024-06-29 11:16:03'),
(232, '查询记录', 3, 221, NULL, NULL, NULL, 1, 'support:job:log:query', 'support:job:log:query', NULL, 221, 0, NULL, 1, 1, 0, 0, 2, '2024-06-29 11:16:37', NULL, '2024-06-29 11:16:37'),
(233, 'knife4j文档', 2, 218, 4, '/knife4j', NULL, 1, NULL, NULL, 'FileWordOutlined', NULL, 1, 'http://localhost:1024/doc.html', 1, 1, 0, 0, 1, '2024-07-02 20:23:50', 1, '2024-07-08 13:49:15'),
(234, 'swagger文档', 2, 218, 5, '/swagger', 'http://localhost:1024/swagger-ui/index.html', 1, NULL, NULL, 'ApiOutlined', NULL, 1, 'http://localhost:1024/swagger-ui/index.html', 1, 1, 0, 0, 1, '2024-07-02 20:35:43', 1, '2024-07-08 13:49:26'),
(250, '三级等保设置', 2, 213, 1, '/support/level3protect/level3-protect-config-index', '/support/level3protect/level3-protect-config-index.vue', 1, NULL, NULL, 'SafetyOutlined', NULL, 0, NULL, 1, 1, 0, 0, 44, '2024-08-13 11:41:02', 44, '2024-08-13 11:58:12');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(251, '敏感数据脱敏', 2, 213, 3, '/support/level3protect/data-masking-list', '/support/level3protect/data-masking-list.vue', 1, NULL, NULL, 'FileProtectOutlined', NULL, 0, NULL, 1, 1, 0, 0, 44, '2024-08-13 11:58:00', 44, '2024-08-13 11:59:49'),
(252, '启用/禁用', 3, 110, NULL, NULL, NULL, 1, 'support:dict:updateDisabled', 'support:dict:updateDisabled', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2025-04-08 19:44:12', 1, '2025-04-08 19:46:03'),
(253, '查询字典数据', 3, 110, NULL, NULL, NULL, 1, 'support:dictData:query', 'support:dictData:query', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2025-04-08 19:46:47', NULL, '2025-04-08 19:46:47'),
(254, '添加字典数据', 3, 110, NULL, NULL, NULL, 1, 'support:dictData:add', 'support:dictData:add', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2025-04-08 19:48:00', NULL, '2025-04-08 19:48:00'),
(255, '更新字典数据', 3, 110, NULL, NULL, NULL, 1, 'support:dictData:update', 'support:dictData:update', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2025-04-08 19:48:19', NULL, '2025-04-08 19:48:19');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(256, '删除字典数据', 3, 110, NULL, NULL, NULL, 1, 'support:dictData:delete', 'support:dictData:delete', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2025-04-08 19:48:38', NULL, '2025-04-08 19:48:38'),
(257, '启用/禁用字典数据', 3, 110, NULL, NULL, NULL, 1, 'support:dictData:updateDisabled', 'support:dictData:updateDisabled', NULL, 110, 0, NULL, 0, 1, 0, 0, 1, '2025-04-08 19:48:57', NULL, '2025-04-08 19:48:57');
INSERT INTO `t_menu` (`menu_id`, `menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`, `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`, `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`, `create_user_id`, `create_time`, `update_user_id`, `update_time`) VALUES
(300, '消息管理', 2, 50, 30, '/message', '/support/message/message-list.vue', 1, NULL, NULL, 'MailOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, '2025-04-09 14:30:04', 1, '2025-04-10 20:19:36');

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--  5.1 让我做运营菜单（2026-10-29 基础菜单 + 2026-10-30 版本管理，共 19 条）
--  1 个目录 + 8 个页面（会员详情 / 任务详情 visible_flag=0 隐藏）+ 10 个按钮权限点
--  同样用 path 查父级、NOT EXISTS 兜底，重复导入不会产生重复菜单
--  演示与文档中心菜单已在 updates/2026-10-29/02_remove_demo_menu.sql 中下线
-- ----------------------------------------------------------------------------
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '让我做运营', 1, 0, 2, '/letmedoit', NULL, NULL, NULL, NULL, 'AppstoreOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '运营概览', 2, p.menu_id, 1, '/letmedoit/dashboard', '/business/letmedoit/dashboard/index.vue', NULL, NULL, NULL, 'DashboardOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/dashboard' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '会员管理', 2, p.menu_id, 2, '/letmedoit/member', '/business/letmedoit/member/member-list.vue', NULL, NULL, NULL, 'TeamOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/member' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '会员详情', 2, p.menu_id, 3, '/letmedoit/member/detail', '/business/letmedoit/member/member-detail.vue', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, 0, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/member/detail' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '帮手关系', 2, p.menu_id, 4, '/letmedoit/helper', '/business/letmedoit/helper/helper-list.vue', NULL, NULL, NULL, 'LinkOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/helper' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '任务管理', 2, p.menu_id, 5, '/letmedoit/task', '/business/letmedoit/task/task-list.vue', NULL, NULL, NULL, 'ScheduleOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/task' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '任务详情', 2, p.menu_id, 6, '/letmedoit/task/detail', '/business/letmedoit/task/task-detail.vue', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, 0, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/task/detail' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '小程序反馈', 2, p.menu_id, 7, '/letmedoit/feedback', '/business/letmedoit/feedback/feedback-list.vue', NULL, NULL, NULL, 'MessageOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/feedback' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本管理', 2, p.menu_id, 8, '/letmedoit/version', '/business/letmedoit/version/version-list.vue', NULL, NULL, NULL, 'DeploymentUnitOutlined', NULL, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit' AND `deleted_flag` = 0 LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '概览查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'dashboard:query', 'dashboard:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/dashboard' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'dashboard:query' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '会员查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'member:query', 'member:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/member' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'member:query' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '帮手查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'helper:query', 'helper:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/helper' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'helper:query' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '任务查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'task:query', 'task:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/task' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'task:query' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '反馈查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'appFeedback:query', 'appFeedback:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/feedback' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appFeedback:query' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '反馈处理', 3, c.menu_id, NULL, NULL, NULL, 1, 'appFeedback:reply', 'appFeedback:reply', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/feedback' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appFeedback:reply' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本查询', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:query', 'appVersion:query', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:query' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本新增', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:add', 'appVersion:add', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:add' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本修改', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:update', 'appVersion:update', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:update' AND `deleted_flag` = 0 LIMIT 1) tmp);
INSERT INTO `t_menu` (`menu_name`, `menu_type`, `parent_id`, `sort`, `path`, `component`, `perms_type`,
                       `api_perms`, `web_perms`, `icon`, `context_menu_id`, `frame_flag`, `frame_url`,
                       `cache_flag`, `visible_flag`, `disabled_flag`, `deleted_flag`,
                       `create_user_id`, `create_time`, `update_user_id`, `update_time`)
SELECT '版本发布', 3, c.menu_id, NULL, NULL, NULL, 1, 'appVersion:publish', 'appVersion:publish', NULL, c.menu_id, 0, NULL, 0, 1, 0, 0, 1, NOW(), NULL, NOW()
FROM (SELECT menu_id FROM `t_menu` WHERE `path` = '/letmedoit/version' AND `deleted_flag` = 0 LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM (SELECT menu_id FROM `t_menu` WHERE `api_perms` = 'appVersion:publish' AND `deleted_flag` = 0 LIMIT 1) tmp);

--  6~7. 业务字典
-- ----------------------------------------------------------------------------
-- 小程序所有状态文案走 AppDictService.label()：字典优先、枚举兜底。
-- 字典表为空不会报错，但后台「字典管理」看不到这 4 本，运营改不动文案。
-- 注意：字典缓存是 Redis，必须在启动服务之前导入，否则空结果会被缓存住。
INSERT INTO `t_dict` (`dict_id`, `dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`) VALUES
(4, '任务状态', 'TASK_STATUS', 't_task.status：任务聚合状态（由参与人状态 + 完成条件算出后落库）', 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict` (`dict_id`, `dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`) VALUES
(5, '参与人状态', 'TASK_PARTICIPANT_STATUS', 't_task_participant.status：一人一格的状态', 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict` (`dict_id`, `dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`) VALUES
(6, '完成条件', 'TASK_COMPLETION_MODE', 't_task.completion_mode：任一人完成 / 全员完成', 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict` (`dict_id`, `dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`) VALUES
(7, '任务事件类型', 'TASK_EVENT_TYPE', 't_task_event.event_type：任务详情页时间线用', 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(9, 4, '0', '预约中', '#6B5BD2', '带开始时间点，到点自动转「待接受」', 60, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(10, 4, '1', '待接受', '#E08A00', '已派出去，等人接受', 50, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(11, 4, '2', '进行中', '#D64C28', '至少一人已接受', 40, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(12, 4, '3', '已完成', '#17A67C', '达到完成条件', 30, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(13, 4, '4', '已拒绝', '#8C8279', '所有参与人都拒绝了', 20, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(14, 4, '5', '已撤回', '#8C8279', '委托人主动撤回', 10, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(15, 5, '0', '待接受', '#E08A00', '', 50, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(16, 5, '1', '已接受', '#D64C28', '', 40, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(17, 5, '2', '已完成', '#17A67C', '', 30, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(18, 5, '3', '已拒绝', '#8C8279', '', 20, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(19, 5, '4', '已跳过', '#A69C93', '任一人完成模式下，其余人自动跳过', 10, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(20, 6, '1', '任一人完成', '#D64C28', '一人完成即整单完成', 20, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(21, 6, '2', '全员完成', '#378ADD', '所有人都完成才算完成', 10, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(22, 7, '1', '创建任务', '#D64C28', '', 90, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(23, 7, '2', '邀请参与', '#E08A00', '', 80, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(24, 7, '3', '接受任务', '#378ADD', '', 70, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(25, 7, '4', '拒绝任务', '#8C8279', '', 60, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(26, 7, '5', '完成任务', '#17A67C', '', 50, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(27, 7, '6', '撤回任务', '#8C8279', '', 40, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(28, 7, '7', '催办', '#E08A00', '', 30, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(29, 7, '8', '定时生效', '#6B5BD2', '预约任务到点自动生效', 20, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(30, 7, '9', '自动跳过', '#A69C93', '任一人完成后其余人自动跳过', 10, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  8. 反馈字典（FEEDBACK_TYPE / FEEDBACK_STATUS）
-- ----------------------------------------------------------------------------
INSERT INTO `t_dict` (`dict_id`, `dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`) VALUES
(8, '反馈类型', 'FEEDBACK_TYPE', 't_app_feedback.type：后台分派用（内容违规要当天处理）', 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict` (`dict_id`, `dict_name`, `dict_code`, `remark`, `disabled_flag`, `create_time`, `update_time`) VALUES
(9, '反馈状态', 'FEEDBACK_STATUS', 't_app_feedback.status：后台处理流转', 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(31, 8, '1', '功能建议', '#6B5BD2', '想要什么功能', 40, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(32, 8, '2', '使用问题', '#E08A00', '用不了、报错、显示不对', 30, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(33, 8, '3', '内容违规', '#D64545', '看到不合适的内容，优先处理', 20, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(34, 8, '4', '其他', '#8C8279', '', 10, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(35, 9, '0', '待处理', '#E08A00', '', 40, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(36, 9, '1', '处理中', '#D64C28', '', 30, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(37, 9, '2', '已解决', '#17A67C', '', 20, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_dict_data` (`dict_data_id`, `dict_id`, `data_value`, `data_label`, `data_style`, `remark`, `sort_order`, `disabled_flag`, `create_time`, `update_time`) VALUES
(38, 9, '3', '已关闭', '#8C8279', '重复反馈 / 无需处理', 10, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  9. 小程序版本（当前对外版本）
--    「我的」页脚、关于弹窗、后续强制更新的版本依据。发版时插新行并把旧行
--    current_flag 置 0，不要直接改这一行的版本号（历史版本要留档）。
-- ----------------------------------------------------------------------------
INSERT INTO `t_app_version` (`version_id`, `app_type`, `version`, `version_label`, `release_note`,
  `release_time`, `min_base_lib`, `force_update_flag`, `current_flag`, `deleted_flag`, `create_time`, `update_time`) VALUES
(1, 'miniapp', '1.0.0', 'v1.0.0', '首个版本：任务委托与提醒（多人任务、帮手、站内通知）', '2026-10-27 00:00:00',
 NULL, 0, 1, 0, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  10. 协议正文（登录必须同意，缺了会拒绝登录）
--   正文里的「运营者」统一写「本小程序作者」，不写真实姓名/邮箱；
--   联系方式引导到小程序内的「我的 → 问题与反馈」。
--   改正文属于措辞调整时不升版本，用户不会被要求重新同意（见 docs/AGREEMENT.md）。
-- ----------------------------------------------------------------------------
INSERT INTO `t_app_agreement` (`agreement_id`, `type`, `title`, `version`, `content`, `effective_time`, `enabled_flag`, `create_time`, `update_time`) VALUES
(1, 'user', '用户协议', '1.0.0', '# 用户协议

版本：1.0.0
生效日期：2026 年 10 月 26 日
运营者：本小程序作者
联系方式：小程序内「我的 → 问题与反馈」

欢迎使用「让我做」小程序（以下简称"本服务"）。本协议是你与本小程序作者（以下简称"我们"）之间就使用本服务所订立的协议。

**请你在使用本服务前完整阅读本协议，特别是以加粗形式提示的免除或限制责任条款。你勾选"我已阅读并同意"或实际使用本服务，即表示你已充分理解并接受本协议全部内容。如你不同意本协议任何条款，请停止注册和使用。**

## 一、协议的接受与变更

1.1 本协议内容包括协议正文及我们已发布或将来可能发布的各类规则、公告、操作指引。上述内容均为本协议不可分割的组成部分，与本协议具有同等法律效力。

1.2 我们有权根据法律法规变化、业务调整或技术升级需要修订本协议。协议修订后，我们会在本服务内以显著方式提示，并更新版本号与生效日期。**修订内容生效后，你继续使用本服务的，视为你已接受修订后的协议；如你不同意，应停止使用并可申请注销账号。**

1.3 若你为未满 18 周岁的未成年人，请在法定监护人陪同下阅读本协议，并在取得监护人同意后使用本服务。

## 二、服务说明

2.1 本服务是一款面向家庭成员及熟人之间的小工具，用于**发布日常小事委托、提醒对方按时完成、确认完成结果**。你可以向已建立"帮手"关系的其他用户布置任务，也可以接受他人布置给你的任务。

2.2 本服务仅提供信息记录与提醒的技术能力，**不参与用户之间任何实际事务的履行**。任务的完成质量、交付结果由用户自行负责，我们不承担担保责任。

2.3 本服务免费提供。如未来推出收费功能，我们会事前明确告知收费项目、标准与方式，由你自主选择是否使用。

2.4 我们有权根据运营需要调整、中断或终止部分或全部服务，但应尽可能提前通知，并保障你已产生数据的合理导出需求。

## 三、账号注册与使用

3.1 你通过微信授权登录本服务，我们将依据你的微信 OpenID 为你创建账号。你应保证使用本人合法持有的微信账号登录，不得转让、出借、出租账号。

3.2 你应妥善保管微信账号及设备，因你自身原因导致账号被他人使用所产生的后果，由你自行承担。发现账号异常时，请及时通过本协议末尾的联系方式通知我们。

3.3 你授权我们获取的微信昵称、头像仅用于在本服务内展示与识别。你可以随时在"我的"页面修改昵称与头像。

3.4 你可以在"我的"页面选择是否授权提供手机号。**手机号为可选信息**，不授权不影响本服务的核心功能使用。

## 四、用户行为规范

4.1 你在使用本服务时，应遵守《中华人民共和国网络安全法》《中华人民共和国个人信息保护法》《网络信息内容生态治理规定》等法律法规，不得制作、复制、发布、传播含有下列内容的信息：

（一）反对宪法确定的基本原则的；
（二）危害国家安全，泄露国家秘密，颠覆国家政权，破坏国家统一的；
（三）损害国家荣誉和利益的；
（四）歪曲、丑化、亵渎、否定英雄烈士事迹和精神的；
（五）宣扬恐怖主义、极端主义的；
（六）煽动民族仇恨、民族歧视，破坏民族团结的；
（七）破坏国家宗教政策，宣扬邪教和封建迷信的；
（八）散布谣言，扰乱经济秩序和社会秩序，破坏社会稳定的；
（九）散布淫秽、色情、赌博、暴力、凶杀、恐怖或者教唆犯罪的；
（十）侮辱、诽谤他人，侵害他人名誉权、隐私权、肖像权、知识产权等合法权益的；
（十一）含有法律、行政法规禁止的其他内容的。

4.2 你不得利用本服务从事下列行为：发布广告或垃圾信息；批量注册账号；使用外挂、脚本等非官方手段访问本服务；干扰本服务正常运行；以任何方式绕过本服务的内容安全检测机制。

4.3 **所有你提交的文本内容与上传的图片，均会经过微信内容安全接口检测。** 检测未通过的，我们有权拒绝发布、予以删除，并可视情节采取警告、限制功能、暂停或终止服务的处理措施。

4.4 因你违反本协议或相关法律法规导致我们或第三方遭受损失的，你应承担相应赔偿责任。

## 五、内容安全与审核

5.1 本服务的文本（任务标题、交代内容、完成备注、拒绝理由、帮手申请附言、昵称）与图片（头像、任务附图、完成凭证）均接入微信内容安全检测能力。

5.2 文本内容在提交时同步检测，未通过则不予发布。图片采用异步检测机制，检测结果回传后如判定违规，我们会自动移除该图片并通过站内通知告知发布者。

5.3 我们有权对违规内容进行删除、屏蔽，并保留相关记录依法向主管部门报告。

## 六、知识产权

6.1 本服务的软件著作权、界面设计、商标、文字与图形素材等知识产权归我们或相应权利人所有。

6.2 你通过本服务发布的任务内容、上传的图片，其知识产权归你或原权利人所有。你授予我们一项**非独占、免费、仅为实现本服务功能所必需**的许可，用于在本服务范围内存储、展示、传输上述内容。

6.3 你保证对发布的内容拥有合法权利，不侵犯任何第三方权益。因你的内容引发权利纠纷的，由你自行承担全部责任。

## 七、个人信息保护

7.1 我们重视你的个人信息保护。关于我们如何收集、使用、存储、共享你的个人信息，以及你享有的权利，请详见《隐私政策》。

7.2 **《隐私政策》是本协议不可分割的组成部分，与本协议具有同等法律效力。**

## 八、服务的变更、中断与终止

8.1 因系统维护、升级或不可抗力（包括但不限于自然灾害、网络故障、黑客攻击、政府行为）导致服务中断的，我们将尽力及时恢复，但在法律允许范围内不承担赔偿责任。

8.2 你有权随时停止使用本服务，并可申请注销账号。注销后，除法律法规要求留存的记录外，我们将删除或匿名化你的个人信息。

8.3 你出现下列情形之一的，我们有权终止向你提供服务：违反法律法规或本协议；账号被用于违法活动；经核实存在严重侵害他人权益的行为。

## 九、免责声明与责任限制

9.1 **本服务仅提供任务记录与提醒的技术工具。用户之间因任务履行产生的争议，应由当事人自行协商解决，我们不作为争议一方，也不承担由此产生的责任。**

9.2 对于因你自身原因（包括但不限于设备故障、网络异常、误操作、微信账号异常）导致的损失，我们不承担责任。

9.3 在法律允许的最大范围内，我们对因使用或无法使用本服务产生的间接损失、可得利益损失不承担赔偿责任。

9.4 本条不排除或限制我们依法应当承担的责任。

## 十、法律适用与争议解决

10.1 本协议的订立、效力、解释、履行及争议解决，适用中华人民共和国大陆地区法律。

10.2 因本协议产生的争议，双方应友好协商解决；协商不成的，任何一方均可向有管辖权的人民法院提起诉讼。

## 十一、其他

11.1 本协议部分条款被认定为无效或不可执行的，不影响其余条款的效力。

11.2 我们未行使或延迟行使本协议项下任何权利，不构成对该权利的放弃。

## 十二、联系我们

如你对本协议有任何疑问、意见或投诉，可通过以下方式联系我们：

运营者：本小程序作者
联系方式：小程序内「我的 → 问题与反馈」

我们将在收到你的反馈后 15 个工作日内予以回复。', '2026-10-26 00:00:00', 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

INSERT INTO `t_app_agreement` (`agreement_id`, `type`, `title`, `version`, `content`, `effective_time`, `enabled_flag`, `create_time`, `update_time`) VALUES
(2, 'privacy', '隐私政策', '1.0.0', '# 隐私政策

版本：1.0.0
生效日期：2026 年 10 月 26 日
运营者：本小程序作者
联系方式：小程序内「我的 → 问题与反馈」

本小程序作者（以下简称"我们"）深知个人信息对你的重要性。我们依据《中华人民共和国个人信息保护法》《中华人民共和国网络安全法》《信息安全技术 个人信息安全规范》等法律法规，制定本政策。

**本政策适用于「让我做」小程序。请你在使用前仔细阅读，特别是以加粗形式标注的内容。你勾选同意并登录使用，即表示你已理解并同意本政策。**

## 一、我们收集哪些信息

我们遵循"最小必要"原则，仅收集实现功能所必需的信息。

### 1.1 你主动提供的信息

| 信息项 | 收集场景 | 是否必需 | 用途 |
| --- | --- | --- | --- |
| 昵称 | 登录后引导填写 / "我的"页修改 | 必需 | 在任务、帮手列表中标识你 |
| 头像 | 你主动选择上传 | 可选 | 在列表中展示；不上传则显示昵称首字色块 |
| 手机号 | 你主动授权获取 | **可选** | 账号找回与身份核验；不授权不影响核心功能 |
| 任务标题、交代内容 | 布置任务时填写 | 必需 | 生成任务并展示给参与者 |
| 任务附图 | 你主动选择上传 | 可选 | 随任务展示给参与者 |
| 完成备注、凭证图片 | 完成任务时填写 | 可选 | 向委托人证明完成情况 |
| 拒绝理由 | 拒绝任务时填写 | 必需 | 让对方知道原因 |
| 帮手申请附言 | 申请添加帮手时填写 | 可选 | 让对方识别你的身份 |

### 1.2 你使用服务时我们自动收集的信息

| 信息项 | 说明 | 用途 |
| --- | --- | --- |
| 微信 OpenID | 你在当前小程序下的唯一标识 | 账号识别与登录 |
| 微信 UnionID | 同一微信开放平台账号下的统一标识（如你授权） | 多端身份打通 |
| 登录时间、登录 IP、客户端标识（User-Agent） | 每次登录时记录 | 账号安全风控、异常登录排查 |
| 帮手关系、邀请码 | 你与他人建立关系时生成 | 实现任务派发范围控制 |
| 内容检测记录 | 提交的文本摘要、图片地址、检测结论 | 履行内容安全法律义务、留存审核证据 |

### 1.3 我们**不会**收集的信息

我们**不会**收集你的地理位置、通讯录、通话记录、短信、剪贴板内容、相册全量照片、麦克风录音、相机实时画面。选择图片时，我们仅获取你**主动选择的那一张**，不会读取相册其他内容。

## 二、我们如何使用信息

2.1 用于提供核心功能：创建账号、建立帮手关系、派发任务、发送站内提醒、记录完成状态。

2.2 用于保障账号与内容安全：识别异常登录、检测违法违规内容、处理投诉与纠纷。

2.3 用于改进服务：以**去标识化、汇总统计**的方式分析功能使用情况，不会定位到具体个人。

2.4 **我们不会将你的个人信息用于本政策未载明的其他用途。** 如需超出本政策范围使用，我们会再次征得你的单独同意。

## 三、信息的存储

3.1 **存储地点**：你的个人信息存储于中华人民共和国境内的服务器（腾讯云广州地域）。我们不会将境内收集的个人信息传输至境外。

3.2 **存储期限**：我们仅在实现本政策所述目的所必需的期限内保留你的个人信息。

- 账号信息、任务数据：账号存续期间持续保存；
- 你注销账号后：我们将在 **30 日内**删除或匿名化处理你的个人信息；
- 法律法规另有规定的（如《网络安全法》要求网络日志留存不少于 6 个月），我们按要求留存，且仅用于配合监管与安全审计，不再用于其他目的。

3.3 当超出保存期限后，我们将对你的个人信息进行删除或匿名化处理。

## 四、信息的共享、转让与公开披露

### 4.1 共享

我们**不会向任何第三方出售你的个人信息**。仅在以下必要情形下共享：

| 接收方 | 共享内容 | 目的 | 说明 |
| --- | --- | --- | --- |
| 深圳市腾讯计算机系统有限公司（微信） | 登录凭证、待检测的文本与图片、消息推送所需标识 | 微信登录、内容安全检测、消息推送 | 微信平台自身的处理规则适用其《微信隐私保护指引》 |
| 腾讯云计算（北京）有限责任公司 | 你上传的图片文件 | 图片存储与访问 | 通过对象存储服务托管，仅用于存储 |

除上述情形外，我们不会与任何第三方共享你的个人信息，除非：

（一）事先获得你的明确同意；
（二）根据法律法规、司法或行政机关强制性要求；
（三）为维护社会公共利益、你或他人的生命财产安全所必需。

### 4.2 转让

我们不会转让你的个人信息。如因合并、分立、收购等原因需要转让，我们会告知你接收方信息，并要求接收方继续受本政策约束；接收方变更原处理目的的，将重新征得你的同意。

### 4.3 公开披露

我们不会公开披露你的个人信息。依法必须披露时，我们会告知你披露的目的、信息类型，并采取符合法律与行业标准的安全防护措施。

## 五、我们如何保护信息

5.1 **传输安全**：你与本服务之间的数据传输采用 HTTPS 加密传输。

5.2 **访问控制**：仅因履行职责需要接触你信息的人员，方可按最小权限访问；我们与该等人员签署保密义务。

5.3 **内容安全**：你提交的文本与图片均接入微信内容安全检测接口，防止违法违规内容传播，同时降低侵权风险。

5.4 **安全事件处置**：如发生个人信息泄露、篡改、丢失等安全事件，我们将立即启动应急预案，采取补救措施，并按法律要求向你告知事件情况、可能影响、已采取的措施及你可自主防范的建议，同时向监管部门报告。

## 六、你的权利

依据《个人信息保护法》，你对自己的个人信息享有以下权利：

6.1 **查阅、复制**：你可在"我的"页面查看昵称、头像等资料；如需完整信息副本，可通过本政策末尾联系方式申请。

6.2 **更正、补充**：你可在"我的"页面直接修改昵称与头像；其他信息有误的，可联系我们更正。

6.3 **删除**：你可以删除自己发布的任务内容、移除已上传的图片；符合法定删除情形时，也可要求我们删除。

6.4 **撤回同意**：你可以通过不授权手机号、不上传头像等方式撤回相应同意。撤回不影响此前基于同意已进行的处理。

6.5 **注销账号**：你可以通过本政策末尾的联系方式申请注销。注销后我们将按本政策第 3.2 条处理你的信息。

6.6 **响应时限**：我们将在收到你的请求并核验身份后 **15 个工作日内**予以答复。对合理请求原则上不收取费用；对无端重复、超出合理限度的请求，我们可能予以拒绝并说明理由。

## 七、未成年人保护

7.1 本服务主要面向成年人。若你为**未满 14 周岁的儿童**，请务必在父母或其他监护人的陪同下阅读本政策，并在取得监护人**明示同意**后使用本服务。

7.2 若我们发现在未事先获得监护人同意的情况下收集了儿童个人信息，将尽快删除相关信息。

7.3 监护人如对儿童个人信息有疑问，可通过本政策末尾联系方式与我们联系。

## 八、本政策的更新

8.1 我们可能因法律法规变化、业务调整而更新本政策。更新后会以显著方式提示你，并更新版本号与生效日期。

8.2 **对于收集信息范围、使用目的、共享对象等发生重大变更的，我们会重新征得你的明示同意。**

8.3 你可在小程序"我的 → 用户协议 / 隐私政策"中随时查阅最新版本。

## 九、联系我们

如你对本政策有任何疑问、意见、投诉或需要行使上述权利，可通过以下方式联系我们：

运营者：本小程序作者
联系方式：小程序内「我的 → 问题与反馈」

我们将在收到后 15 个工作日内回复。

如你对我们的答复不满意，或认为我们的个人信息处理行为损害了你的合法权益，你还可以向网信、电信、公安、市场监管等主管部门投诉举报，或向有管辖权的人民法院提起诉讼。', '2026-10-26 00:00:00', 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  8. 定时任务
-- ----------------------------------------------------------------------------
-- cron 是 Spring 的 6 段式（秒 分 时 日 月 周），不要用 Quartz 的 ? 占位符。
-- 集群部署时由 SmartJobExecutor 的 Redisson 锁互斥，只会有一个实例执行。
INSERT INTO `t_smart_job` (`job_name`, `job_class`, `trigger_type`, `trigger_value`, `enabled_flag`, `param`, `sort`, `remark`, `deleted_flag`, `update_name`, `create_time`, `update_time`) VALUES
('任务到点生效与到期提醒', 'net.lab1024.sa.app.module.task.job.TaskScheduleJob', 'cron', '0 * * * * *', 1, NULL, 10, '每分钟：预约任务转待接受 + 给未完成的参与人发到期提醒', 0, '系统', '2026-01-01 00:00:00', '2026-01-01 00:00:00');

-- ----------------------------------------------------------------------------
--  9. 公告类型
-- ----------------------------------------------------------------------------
INSERT INTO `t_notice_type` (`notice_type_id`, `notice_type_name`, `create_time`, `update_time`) VALUES
(1, '新闻', '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO `t_notice_type` (`notice_type_id`, `notice_type_name`, `create_time`, `update_time`) VALUES
(2, '通知', '2026-01-01 00:00:00', '2026-01-01 00:00:00');

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
--  六、上线自检（执行完脚本后手工跑一遍）
-- ----------------------------------------------------------------------------
-- 1) 表数量应为 46
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE();
--
-- 2) 核心表必须存在
-- SELECT table_name FROM information_schema.tables
--  WHERE table_schema = DATABASE()
--    AND table_name IN ('t_wx_member','t_helper','t_helper_request','t_content_check',
--                       't_task','t_task_participant','t_task_event','t_task_notice',
--                       't_app_agreement','t_app_agreement_record','t_app_feedback',
--                       't_app_version','t_file','t_dict','t_dict_data');
--
-- 3) 业务表必须全空（每行都应是 0）
-- SELECT 't_wx_member' t, COUNT(*) c FROM t_wx_member
-- UNION ALL SELECT 't_task', COUNT(*) FROM t_task
-- UNION ALL SELECT 't_task_participant', COUNT(*) FROM t_task_participant
-- UNION ALL SELECT 't_helper', COUNT(*) FROM t_helper
-- UNION ALL SELECT 't_content_check', COUNT(*) FROM t_content_check
-- UNION ALL SELECT 't_app_feedback', COUNT(*) FROM t_app_feedback
-- UNION ALL SELECT 't_app_agreement_record', COUNT(*) FROM t_app_agreement_record;
--
-- 4) 协议必须各一行且启用（否则登录被拒），正文里不能有占位符/邮箱
-- SELECT type, version, enabled_flag, CHAR_LENGTH(content) len FROM t_app_agreement;
-- SELECT type, (content LIKE '%〔%') has_placeholder, (content LIKE '%@%') has_email,
--        (content LIKE '%住所地%') has_domicile
--   FROM t_app_agreement WHERE enabled_flag = 1;      -- 三列都应为 0
--
-- 5) 版本只能有一行 current_flag = 1
-- SELECT app_type, COUNT(1) FROM t_app_version
--  WHERE current_flag = 1 AND deleted_flag = 0 GROUP BY app_type;
-- SELECT version, version_label, current_flag FROM t_app_version;
--
-- 6) 定时任务必须注册（否则到点生效与到期提醒全部静默失效）
-- SELECT job_name, trigger_value, enabled_flag FROM t_smart_job
--  WHERE job_class = 'net.lab1024.sa.app.module.task.job.TaskScheduleJob';
--
-- 7) 字典 6 本齐全（items 分别 6/5/2/9/4/4）
-- SELECT d.dict_code, COUNT(x.dict_data_id) items
--   FROM t_dict d LEFT JOIN t_dict_data x ON x.dict_id = d.dict_id
--  WHERE d.dict_code IN ('TASK_STATUS','TASK_PARTICIPANT_STATUS','TASK_COMPLETION_MODE',
--                        'TASK_EVENT_TYPE','FEEDBACK_TYPE','FEEDBACK_STATUS')
--  GROUP BY d.dict_code;
--
-- 8) 后台账号唯一
-- SELECT employee_id, login_name, administrator_flag FROM t_employee;
--
-- 9) 后台菜单 96 条（77 条框架菜单 + 19 条让我做运营；其中 2 条为隐藏详情页、3 条历史停用）
-- SELECT COUNT(*) FROM t_menu WHERE deleted_flag = 0;
--
-- 10) 导完字典后重启一次服务（或清 Redis 的 dict 缓存），确保字典缓存重建。
-- ============================================================================
