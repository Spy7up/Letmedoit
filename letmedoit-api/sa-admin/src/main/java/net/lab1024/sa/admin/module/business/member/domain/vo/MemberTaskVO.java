package net.lab1024.sa.admin.module.business.member.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 会员关联的任务（委托人 / 参与者任一身份）
 *
 * @Author 1024创新实验室
 */
@Data
public class MemberTaskVO {

    private Long taskId;

    private String title;

    private Long creatorId;

    private String creatorNickname;

    @Schema(description = "聚合状态 0预约中 1待接受 2进行中 3已完成 4已拒绝 5已撤回")
    private Integer status;

    private LocalDateTime deadline;

    private LocalDateTime createTime;

    @Schema(description = "当前会员在该任务中的身份：creator 委托人，participant 参与者")
    private String memberRole;

    @Schema(description = "参与者状态 0待接受 1已接受 2已完成 3已拒绝 4已跳过；委托人为空")
    private Integer participantStatus;

    private LocalDateTime completeTime;

    @Schema(description = "是否准时完成：完成时间不晚于截止时间")
    private Boolean onTimeFlag;
}
