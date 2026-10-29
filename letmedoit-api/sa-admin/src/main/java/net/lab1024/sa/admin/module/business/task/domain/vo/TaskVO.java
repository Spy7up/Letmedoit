package net.lab1024.sa.admin.module.business.task.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 任务列表项
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "任务列表项")
public class TaskVO {

    private Long taskId;

    private String title;

    private Long creatorId;

    private String creatorNickname;

    @Schema(description = "聚合状态 0预约中 1待接受 2进行中 3已完成 4已拒绝 5已撤回")
    private Integer status;

    @Schema(description = "完成条件 1任一人完成 2全员完成")
    private Integer completionMode;

    private LocalDateTime startTime;

    private LocalDateTime deadline;

    private LocalDateTime createTime;

    private Long participantCount;

    private Long acceptedCount;

    private Long completedCount;

    @Schema(description = "是否逾期：未结束且已过截止时间")
    private Boolean overdueFlag;
}
