package net.lab1024.sa.app.module.member.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.member.domain.entity.WxMemberEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Collection;
import java.util.List;

/**
 * 小程序会员 DAO
 *
 * @author smart-admin
 */
@Mapper
public interface WxMemberDao extends BaseMapper<WxMemberEntity> {

    /**
     * 批量查询会员
     * <p>
     * 任务参与者、帮手列表等处统一走 IN 批量取，禁止在循环里单条查
     *
     * @param memberIds 会员ID集合，调用方需保证非空
     * @return 会员列表
     */
    List<WxMemberEntity> queryByIds(@Param("memberIds") Collection<Long> memberIds);

    /**
     * 注销账号：匿名化 + 逻辑删除
     * <p>
     * open_id 必须换掉（唯一索引），否则同一个人重新登录会被判成「账号状态异常」，
     * 永远进不来。换成 del_{memberId}_{时间戳} 之后，再次登录会注册成一个全新账号。
     *
     * @param memberId        会员ID
     * @param anonymousOpenId 匿名 openId
     * @param anonymousName   匿名昵称（页面上展示为已注销用户）
     * @param updateTime      更新时间
     * @return 受影响行数，0 表示已经注销过
     */
    int anonymizeAndDelete(@Param("memberId") Long memberId,
                           @Param("anonymousOpenId") String anonymousOpenId,
                           @Param("anonymousName") String anonymousName,
                           @Param("updateTime") java.time.LocalDateTime updateTime);

    /**
     * 按邀请码查询会员
     *
     * @param inviteCode 邀请码
     * @return 会员
     */
    WxMemberEntity queryByInviteCode(@Param("inviteCode") String inviteCode);
}
