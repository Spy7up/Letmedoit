package net.lab1024.sa.admin.module.business.dashboard.dao;

import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardOverviewVO;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardRecentMemberVO;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardTaskStatusVO;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardTrendItemVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface DashboardDao {

    DashboardOverviewVO selectOverview();

    List<DashboardTaskStatusVO> selectTaskStatusList();

    List<DashboardRecentMemberVO> selectRecentMemberList();

    List<DashboardTrendItemVO> selectMemberTrend(@Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);

    List<DashboardTrendItemVO> selectTaskTrend(@Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);

    List<DashboardTrendItemVO> selectCompletedTrend(@Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);
}
