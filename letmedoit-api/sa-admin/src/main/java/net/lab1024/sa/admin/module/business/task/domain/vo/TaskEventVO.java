package net.lab1024.sa.admin.module.business.task.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 任务事件（时间线）
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "任务事件")
public class TaskEventVO {

    private Long eventId;

    @Schema(description = "事件类型 1创建 2邀请 3接受 4拒绝 5完成 6撤回 7催办 8定时生效 9跳过")
    private Integer eventType;

    private String content;

    private Long actorId;

    private String actorNickname;

    private LocalDateTime createTime;
}
