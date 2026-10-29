package net.lab1024.sa.admin.module.business.task.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 任务参与者
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "任务参与者")
public class TaskParticipantVO {

    private Long participantId;

    private Long memberId;

    private String nickname;

    private String avatar;

    @Schema(description = "参与状态 0待接受 1已接受 2已完成 3已拒绝 4已跳过")
    private Integer status;

    private LocalDateTime completeTime;

    private String completeRemark;

    @Schema(description = "凭证图片，JSON 数组字符串")
    private String completeImages;

    private String rejectReason;

    @Schema(description = "是否准时完成：完成时间不晚于截止时间")
    private Boolean onTimeFlag;
}
