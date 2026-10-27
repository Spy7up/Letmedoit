package net.lab1024.sa.app.module.feedback.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.feedback.domain.entity.AppFeedbackEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 问题与反馈 DAO
 * <p>
 * 小程序端只有「新增」，用 BaseMapper.insert 就够。
 * <p>
 * 后台列表/回复要走 sa-admin 自己的 DAO：sa-admin 不依赖 sa-app，
 * 两边共用同一张表 t_app_feedback，字段与索引已按后台列表的查询路径设计，
 * 详见 docs/问题与反馈.md「后台接入设计」。
 * <p>
 * ⚠️ 注入时字段名必须写 appFeedbackDao：项目统一用 @Resource，它**先按字段名匹配**，
 * 叫 feedbackDao 会命中 sa-base 自带的同名 Mapper，启动时报「dynamic proxy 类型不匹配」。
 *
 * @author letmedoit
 */
@Mapper
public interface AppFeedbackDao extends BaseMapper<AppFeedbackEntity> {
}
