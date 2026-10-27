package net.lab1024.sa.app.module.helper.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.helper.domain.entity.HelperRequestEntity;
import net.lab1024.sa.app.module.helper.domain.vo.HelperRequestVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 帮手申请 DAO
 *
 * @author letmedoit
 */
@Mapper
public interface HelperRequestDao extends BaseMapper<HelperRequestEntity> {

    /**
     * 我收到的待处理申请
     *
     * @param memberId    当前会员
     * @param status      申请状态
     * @param deletedFlag 删除标识
     * @return 申请列表
     */
    List<HelperRequestVO> queryByToMember(@Param("memberId") Long memberId,
                                          @Param("status") Integer status,
                                          @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 按主键查询
     *
     * @param requestId   申请ID
     * @param deletedFlag 删除标识
     * @return 申请
     */
    HelperRequestEntity queryById(@Param("requestId") Long requestId,
                                  @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 查询两人之间是否已有待处理申请
     *
     * @param fromMemberId 发起人
     * @param toMemberId   接收人
     * @param status       状态
     * @param deletedFlag  删除标识
     * @return 申请
     */
    HelperRequestEntity queryPending(@Param("fromMemberId") Long fromMemberId,
                                     @Param("toMemberId") Long toMemberId,
                                     @Param("status") Integer status,
                                     @Param("deletedFlag") Boolean deletedFlag);

    /**
     * 条件更新申请状态（幂等）
     *
     * @param requestId    申请ID
     * @param expectStatus 期望的当前状态
     * @param status       目标状态
     * @param updateTime   更新时间
     * @return 受影响行数
     */
    /**
     * 注销账号时清掉该会员的待处理申请（收到的 + 发出的）
     *
     * @param memberId      会员ID
     * @param pendingStatus 待处理状态（由 service 传入，XML 不写死）
     * @param updateTime    更新时间
     * @return 受影响行数
     */
    int logicDeletePendingByMember(@Param("memberId") Long memberId,
                                   @Param("pendingStatus") Integer pendingStatus,
                                   @Param("updateTime") java.time.LocalDateTime updateTime);

    int updateStatus(@Param("requestId") Long requestId,
                     @Param("expectStatus") Integer expectStatus,
                     @Param("status") Integer status,
                     @Param("updateTime") LocalDateTime updateTime);
}
