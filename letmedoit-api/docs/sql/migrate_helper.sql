-- ============================================================
-- 「让我做」好友 → 帮手 迁移脚本
-- ------------------------------------------------------------
-- 适用对象：**已经执行过** letmedoit_init.sql / letmedoit_task.sql 的旧库
--           （表名仍是 t_friend / t_friend_request）
-- 全新库：不用跑本脚本，直接执行 letmedoit_init.sql 即可（建的就是 t_helper）
--
-- 幂等设计：每一步都先查 information_schema 再 PREPARE 执行，
--           重复执行只会打印 skip，不会报错。
--
-- 覆盖范围：
--   t_friend                    → t_helper
--   t_friend_request            → t_helper_request
--   friend_id                   → helper_id
--   friend_member_id            → helper_member_id
--   uk_member_friend            → uk_member_helper
--   idx_friend_member           → idx_helper_member
--
-- 数据不丢：RENAME / CHANGE 都是元数据变更，行数据与自增游标原样保留。
-- ============================================================

SET @db := DATABASE();

-- ------------------------------------------------------------
-- 1. 表重命名
-- ------------------------------------------------------------
SET @old := (SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_friend');
SET @new := (SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper');
SET @sql := IF(@old = 1 AND @new = 0,
               'RENAME TABLE `t_friend` TO `t_helper`',
               'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @old := (SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_friend_request');
SET @new := (SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper_request');
SET @sql := IF(@old = 1 AND @new = 0,
               'RENAME TABLE `t_friend_request` TO `t_helper_request`',
               'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 2. 列重命名：t_helper
--    保留原类型 / AUTO_INCREMENT / 注释，只改列名
-- ------------------------------------------------------------
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper' AND COLUMN_NAME = 'friend_id');
SET @sql := IF(@c = 1,
               'ALTER TABLE `t_helper` CHANGE COLUMN `friend_id` `helper_id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键''',
               'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper' AND COLUMN_NAME = 'friend_member_id');
SET @sql := IF(@c = 1,
               'ALTER TABLE `t_helper` CHANGE COLUMN `friend_member_id` `helper_member_id` BIGINT(20) UNSIGNED NOT NULL COMMENT ''帮手会员ID''',
               'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 3. 索引重命名
--    MySQL 8.0 支持 RENAME INDEX；5.7 走 DROP + ADD 兜底
-- ------------------------------------------------------------
SET @i := (SELECT COUNT(*) FROM information_schema.STATISTICS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper' AND INDEX_NAME = 'uk_member_friend');
SET @n := (SELECT COUNT(*) FROM information_schema.STATISTICS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper' AND INDEX_NAME = 'uk_member_helper');
SET @sql := IF(@i > 0 AND @n = 0,
               'ALTER TABLE `t_helper` RENAME INDEX `uk_member_friend` TO `uk_member_helper`',
               'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @i := (SELECT COUNT(*) FROM information_schema.STATISTICS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper' AND INDEX_NAME = 'idx_friend_member');
SET @n := (SELECT COUNT(*) FROM information_schema.STATISTICS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 't_helper' AND INDEX_NAME = 'idx_helper_member');
SET @sql := IF(@i > 0 AND @n = 0,
               'ALTER TABLE `t_helper` RENAME INDEX `idx_friend_member` TO `idx_helper_member`',
               'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 4. 表注释
-- ------------------------------------------------------------
ALTER TABLE `t_helper` COMMENT = '帮手关系';
ALTER TABLE `t_helper_request` COMMENT = '帮手申请';

-- ------------------------------------------------------------
-- 5. 邀请码字段注释（t_wx_member.invite_code）
-- ------------------------------------------------------------
ALTER TABLE `t_wx_member`
  MODIFY COLUMN `invite_code` VARCHAR(8) DEFAULT NULL COMMENT '邀请码（6位，加帮手用）';

-- ------------------------------------------------------------
-- 6. 自检：应输出 4 行，且都不含 friend
-- ------------------------------------------------------------
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @db
  AND TABLE_NAME IN ('t_helper', 't_helper_request')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
