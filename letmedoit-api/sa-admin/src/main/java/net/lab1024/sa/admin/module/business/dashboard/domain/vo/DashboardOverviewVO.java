package net.lab1024.sa.admin.module.business.dashboard.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Schema(description = "运营总览")
public class DashboardOverviewVO {

    private Long memberCount;

    private Long todayMemberCount;

    private Long helperPairCount;

    private Long taskCount;

    private Long todayTaskCount;

    private Long completedTaskCount;

    private Long completedParticipantCount;

    private Long onTimeParticipantCount;

    private Long pendingFeedbackCount;

    @Schema(description = "百分比；无完成样本时为空")
    private BigDecimal onTimeRate;

    @Schema(description = "百分比；无任务时为空")
    private BigDecimal taskCompletionRate;

    private List<DashboardTaskStatusVO> taskStatusList;

    private List<DashboardRecentMemberVO> recentMemberList;
}
