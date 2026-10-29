package net.lab1024.sa.admin.module.business.dashboard.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Data
@Schema(description = "运营趋势")
public class DashboardTrendVO {

    private List<String> dateList;

    private List<Long> memberCountList;

    private List<Long> taskCountList;

    private List<Long> completedCountList;
}
