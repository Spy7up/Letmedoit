package net.lab1024.sa.app.module.helper.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.helper.domain.entity.HelperEntity;
import net.lab1024.sa.app.module.helper.domain.vo.HelperVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 帮手关系 DAO
 *
 * @author letmedoit
 */
@Mapper
public interface HelperDao extends BaseMapper<HelperEntity> {

    /**
     * 我的帮手列表（含进行中任务数、最近互动时间，一次查询取完）
     *
     * @param memberId             当前会员
     * @param keyword              备注或昵称关键词，可为空
     * @param deletedFlag          删除标识
     * @param activeTaskStatusList 未结束的任务状态，由 service 传入
     * @return 帮手列表
     */
    List<HelperVO> queryList(@Param("memberId") Long memberId,
                             @Param("keyword") String keyword,
                             @Param("deletedFlag") Boolean deletedFlag,
                             @Param("activeTaskStatusList") List<Integer> activeTaskStatusList);

    /**
     * 按主键查询关系
     *
     * @param helperId    关系ID
     * @param deletedFlag 删除标识
     * @return 关系
     */
    HelperEntity queryById(@Param("helperId") Long helperId, @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 查询两人之间的直接关系
     *
     * @param memberId       会员ID
     * @param helperMemberId 帮手会员ID
     * @param deletedFlag    删除标识
     * @return 关系
     */
    HelperEntity queryByMemberAndHelper(@Param("memberId") Long memberId,
                                        @Param("helperMemberId") Long helperMemberId,
                                        @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 帮手会员ID集合（建任务时校验参与者是否都是帮手）
     *
     * @param memberId    当前会员
     * @param deletedFlag 删除标识
     * @return 帮手会员ID
     */
    List<Long> queryHelperMemberIds(@Param("memberId") Long memberId,
                                    @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 帮手数量
     *
     * @param memberId    当前会员
     * @param deletedFlag 删除标识
     * @return 数量
     */
    Integer countByMember(@Param("memberId") Long memberId, @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 建立关系：已存在（含被逻辑删除过）则复活，靠唯一索引保证不重复
     *
     * @param memberId       会员ID
     * @param helperMemberId 帮手会员ID
     * @param now            当前时间
     * @return 受影响行数
     */
    int upsert(@Param("memberId") Long memberId,
                @Param("helperMemberId") Long helperMemberId,
                @Param("now") LocalDateTime now);

    /**
     * 解除帮手：双向逻辑删除
     *
     * @param memberId       会员ID
     * @param helperMemberId 帮手会员ID
     * @param updateTime     更新时间
     * @return 受影响行数（正常为 2）
     */
    /**
     * 注销账号时清空该会员的全部帮手关系（双向）
     *
     * @param memberId   会员ID
     * @param updateTime 更新时间
     * @return 受影响行数
     */
    int logicDeleteAllByMember(@Param("memberId") Long memberId,
                               @Param("updateTime") java.time.LocalDateTime updateTime);

    int removeBoth(@Param("memberId") Long memberId,
                   @Param("helperMemberId") Long helperMemberId,
                   @Param("updateTime") LocalDateTime updateTime);
}
