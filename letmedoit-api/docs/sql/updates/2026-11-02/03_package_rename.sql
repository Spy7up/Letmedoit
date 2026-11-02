-- ============================================================================
-- 2026-11-02 / 03 —— 代码包名从 net.lab1024 改为 net.letmedoit
--
-- 后端全量包名重构（sa-base / sa-admin / sa-app 的 612 个 java 文件、
-- 4 个 pom、全部 mapper XML namespace 与扫描配置）。
--
-- 数据库里唯一存了「全限定类名」的地方是 t_smart_job.job_class：
-- 定时作业按类名反射加载，不同步就会「启动自检报找不到类 + 定时任务静默不跑」。
--
-- 影响：只改 job_class 一列，可重复执行。
-- 顺序：必须【先执行本脚本，再启动新代码】；否则旧代码起不来/作业不跑。
-- ============================================================================

UPDATE `t_smart_job`
SET `job_class` = REPLACE(`job_class`, 'net.lab1024.', 'net.letmedoit.')
WHERE `job_class` LIKE 'net.lab1024.%';

-- 验证：应返回 1 行，且 job_class = net.letmedoit.sa.app.module.task.job.TaskScheduleJob
-- SELECT job_name, job_class, trigger_value, enabled_flag
-- FROM t_smart_job
-- WHERE job_class LIKE '%TaskScheduleJob';
