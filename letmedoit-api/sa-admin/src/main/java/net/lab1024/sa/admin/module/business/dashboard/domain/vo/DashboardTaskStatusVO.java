package net.lab1024.sa.admin.module.business.dashboard.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "任务状态分布")
public class DashboardTaskStatusVO {

    private Integer status;

    private Long count;
}
