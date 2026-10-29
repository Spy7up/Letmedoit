package net.lab1024.sa.admin.module.business.member.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 会员列表项（含个人指标）
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "会员列表项")
public class MemberVO {

    private Long memberId;

    private String nickname;

    private String avatar;

    private String inviteCode;

    private Boolean disabledFlag;

    private LocalDateTime createTime;

    private LocalDateTime lastLoginTime;

    @Schema(description = "帮手上限数，按单方向关系计数")
    private Long helperCount;

    @Schema(description = "作为委托人发起的任务数")
    private Long createdTaskCount;

    @Schema(description = "作为参与者的任务数（关联有效任务）")
    private Long participantCount;

    @Schema(description = "完成样本数：参与者已完成且有完成时间")
    private Long completedCount;

    @Schema(description = "准时完成数：完成时间不晚于任务截止时间")
    private Long onTimeCount;

    @Schema(description = "准时率百分比，零样本为空")
    private BigDecimal onTimeRate;
}
