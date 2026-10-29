package net.lab1024.sa.admin.module.business.dashboard.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
@Schema(description = "运营趋势查询")
public class DashboardTrendQueryForm {

    @Min(value = 7, message = "趋势最少查询7天")
    @Max(value = 90, message = "趋势最多查询90天")
    @Schema(description = "最近天数，默认7", example = "7")
    private Integer days = 7;
}
