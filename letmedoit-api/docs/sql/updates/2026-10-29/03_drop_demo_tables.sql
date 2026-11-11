-- ============================================================================
-- 2026-10-29 / 03_drop_demo_tables.sql
-- 物理删除 SmartAdmin 演示与框架自建功能遗留的 12 张表（代码侧已同步删除）
--
-- 删除清单：
--   演示业务      t_goods / t_category
--   OA 演示       t_oa_bank / t_oa_enterprise / t_oa_enterprise_employee / t_oa_invoice
--   帮助文档      t_help_doc / t_help_doc_catalog / t_help_doc_relation / t_help_doc_view_record
--   框架功能      t_change_log（更新日志）/ t_feedback（框架意见反馈）
--
-- ⚠️ 这是不可回滚的数据破坏操作，执行前必须备份：
--   mysqldump -h <host> -u <user> -p <库名> \
--     t_goods t_category t_oa_bank t_oa_enterprise t_oa_enterprise_employee t_oa_invoice \
--     t_help_doc t_help_doc_catalog t_help_doc_relation t_help_doc_view_record \
--     t_change_log t_feedback > backup_demo_tables_20261029.sql
--
-- 依赖已清理（否则删表后会有死接口）：
--   1. 前端页面与菜单：见 02_remove_demo_menu.sql（t_menu 已删对应 60 条）
--   2. 后端代码：sa-admin business/{goods,category,oa}、sa-base support/{changelog,feedback,helpdoc} 已删除
--   3. 保留表不受影响：t_menu / t_role_menu / t_wx_* / t_task* / t_app_* 等
-- ============================================================================
SET NAMES utf8mb4;

DROP TABLE IF EXISTS `t_goods`;
DROP TABLE IF EXISTS `t_category`;
DROP TABLE IF EXISTS `t_oa_bank`;
DROP TABLE IF EXISTS `t_oa_enterprise`;
DROP TABLE IF EXISTS `t_oa_enterprise_employee`;
DROP TABLE IF EXISTS `t_oa_invoice`;
DROP TABLE IF EXISTS `t_help_doc`;
DROP TABLE IF EXISTS `t_help_doc_catalog`;
DROP TABLE IF EXISTS `t_help_doc_relation`;
DROP TABLE IF EXISTS `t_help_doc_view_record`;
DROP TABLE IF EXISTS `t_change_log`;
DROP TABLE IF EXISTS `t_feedback`;

-- ----------------------------------------------------------------------------
-- 自检：下面两条都应为 0
-- ----------------------------------------------------------------------------
-- SELECT COUNT(*) FROM information_schema.tables
--  WHERE table_schema = DATABASE()
--    AND table_name IN ('t_goods','t_category','t_oa_bank','t_oa_enterprise','t_oa_enterprise_employee',
--                       't_oa_invoice','t_help_doc','t_help_doc_catalog','t_help_doc_relation',
--                       't_help_doc_view_record','t_change_log','t_feedback');
--
-- SELECT COUNT(*) FROM t_menu WHERE deleted_flag = 0
--    AND (api_perms LIKE 'support:changeLog%' OR api_perms LIKE 'support:helpDoc%'
--         OR api_perms LIKE 'feedback:%' OR api_perms LIKE 'help-doc%');
