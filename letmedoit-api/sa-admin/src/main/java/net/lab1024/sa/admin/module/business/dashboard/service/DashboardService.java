package net.lab1024.sa.admin.module.business.dashboard.service;

import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.dashboard.dao.DashboardDao;
import net.lab1024.sa.admin.module.business.dashboard.domain.form.DashboardTrendQueryForm;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardOverviewVO;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardTrendItemVO;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardTrendVO;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class DashboardService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("MM-dd");

    @Resource
    private DashboardDao dashboardDao;

    public ResponseDTO<DashboardOverviewVO> overview() {
        DashboardOverviewVO overview = dashboardDao.selectOverview();
        overview.setOnTimeRate(this.percent(overview.getOnTimeParticipantCount(), overview.getCompletedParticipantCount()));
        overview.setTaskCompletionRate(this.percent(overview.getCompletedTaskCount(), overview.getTaskCount()));
        overview.setTaskStatusList(dashboardDao.selectTaskStatusList());
        overview.setRecentMemberList(dashboardDao.selectRecentMemberList());
        return ResponseDTO.ok(overview);
    }

    public ResponseDTO<DashboardTrendVO> trend(DashboardTrendQueryForm queryForm) {
        int days = queryForm.getDays() == null ? 7 : queryForm.getDays();
        LocalDate today = LocalDate.now();
        LocalDate startDate = today.minusDays(days - 1L);
        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = today.plusDays(1).atStartOfDay();

        Map<String, Long> memberMap = this.toMap(dashboardDao.selectMemberTrend(startTime, endTime));
        Map<String, Long> taskMap = this.toMap(dashboardDao.selectTaskTrend(startTime, endTime));
        Map<String, Long> completedMap = this.toMap(dashboardDao.selectCompletedTrend(startTime, endTime));

        DashboardTrendVO trend = new DashboardTrendVO();
        trend.setDateList(new ArrayList<>(days));
        trend.setMemberCountList(new ArrayList<>(days));
        trend.setTaskCountList(new ArrayList<>(days));
        trend.setCompletedCountList(new ArrayList<>(days));
        for (int i = 0; i < days; i++) {
            LocalDate date = startDate.plusDays(i);
            String key = date.toString();
            trend.getDateList().add(date.format(DATE_FORMATTER));
            trend.getMemberCountList().add(memberMap.getOrDefault(key, 0L));
            trend.getTaskCountList().add(taskMap.getOrDefault(key, 0L));
            trend.getCompletedCountList().add(completedMap.getOrDefault(key, 0L));
        }
        return ResponseDTO.ok(trend);
    }

    private Map<String, Long> toMap(List<DashboardTrendItemVO> list) {
        return list.stream().collect(Collectors.toMap(DashboardTrendItemVO::getStatDate, DashboardTrendItemVO::getCount, (a, b) -> b));
    }

    private BigDecimal percent(Long numerator, Long denominator) {
        if (denominator == null || denominator == 0 || numerator == null) {
            return null;
        }
        return BigDecimal.valueOf(numerator).multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(denominator), 2, RoundingMode.HALF_UP);
    }
}
