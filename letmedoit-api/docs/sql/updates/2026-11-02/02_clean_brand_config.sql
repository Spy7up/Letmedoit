-- ============================================================================
-- 2026-11-02 / 02 —— 清理框架遗留配置与示例文案
--
-- 1) 删除「万能密码」配置（config_key = super_password）
--    这条配置原本带着框架默认值，等于一个可绕过密码直接登录后台的后门。
--    删除后 LoginService 里 superPassword 为 null，登录逻辑按「未启用」处理；
--    确实需要临时使用时，在后台「参数配置」里手动新增，用完随即删除。
--
-- 2) 修正 t_notice.document_number 的列注释（原文案带框架品牌）
--
-- 影响：仅删除 1 条配置记录 + 改 1 个列注释，不动业务数据。可重复执行。
-- ============================================================================

-- 1) 万能密码后门
DELETE FROM `t_config` WHERE `config_key` = 'super_password';

-- 2) 列注释（MODIFY 会重写整列定义，必须把 COMMENT 一起带上）
ALTER TABLE `t_notice`
    MODIFY COLUMN `document_number` varchar(1000) DEFAULT NULL COMMENT '文号，如：发文〔2026〕字第1号';

-- 3) 顺带把三级等保配置的示例 remark 改成有意义的说明
UPDATE `t_config`
SET `remark` = '后台安全策略（登录锁定、密码复杂度、上传大小）'
WHERE `config_key` = 'level3_protect_config'
  AND (`remark` IS NULL OR `remark` LIKE '%Sample%');

-- 4) 删除框架自带的两条示例定时作业（enabled_flag=0，从未执行，只会在后台列表里占位）
DELETE FROM `t_smart_job`
WHERE `job_class` IN (
    'net.letmedoit.sa.base.module.support.job.sample.SmartJobSample1',
    'net.letmedoit.sa.base.module.support.job.sample.SmartJobSample2'
);

-- 验证：应只剩业务作业 TaskScheduleJob
-- SELECT job_id, job_name, job_class, enabled_flag FROM t_smart_job;
