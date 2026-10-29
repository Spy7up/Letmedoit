package net.lab1024.sa.admin.module.business.task.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 任务详情
 *
 * @Author 1024创新实验室
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "任务详情")
public class TaskDetailVO extends TaskVO {

    private String creatorAvatar;

    private String description;

    @Schema(description = "附图，JSON 数组字符串")
    private String images;

    @Schema(description = "开始时间点是否通知参与者")
    private Boolean startNotifyFlag;

    private Integer remindMinutes;

    private Integer editCount;

    private LocalDateTime updateTime;

    private List<TaskParticipantVO> participantList;

    private List<TaskEventVO> eventList;
}
