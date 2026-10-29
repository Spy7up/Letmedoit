package net.lab1024.sa.admin.module.business.member.dao;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.member.domain.form.MemberQueryForm;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberDayStatVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberDetailVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberHelperVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberTaskVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 小程序会员（只读）
 *
 * @Author 1024创新实验室
 */
@Mapper
public interface MemberDao {

    List<MemberVO> query(Page<?> page, @Param("query") MemberQueryForm query);

    /**
     * 单个会员基础信息 + 指标
     */
    MemberDetailVO selectDetail(@Param("memberId") Long memberId);

    /**
     * 会员的帮手列表（单方向，member_id = 当前会员）
     */
    List<MemberHelperVO> selectHelperList(@Param("memberId") Long memberId);

    /**
     * 会员相关任务（委托人 + 参与者合并）
     */
    List<MemberTaskVO> selectTaskList(@Param("memberId") Long memberId);

    /**
     * 会员按天完成统计
     */
    List<MemberDayStatVO> selectDayStat(@Param("memberId") Long memberId, @Param("startTime") LocalDateTime startTime,
                                        @Param("endTime") LocalDateTime endTime);

    /**
     * 收到的待处理帮手申请
     */
    Long selectPendingHelperRequestCount(@Param("memberId") Long memberId);
}
