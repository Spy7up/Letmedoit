package net.lab1024.sa.admin.module.business.feedback.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 小程序反馈
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "小程序反馈")
public class AppFeedbackVO {

    private Long feedbackId;

    private Long memberId;

    private String memberNickname;

    private String memberAvatar;

    @Schema(description = "反馈类型 1功能建议 2使用问题 3内容违规 4其他")
    private Integer type;

    private String content;

    @Schema(description = "反馈图片，JSON 数组字符串，最多 3 张")
    private String images;

    private String contact;

    @Schema(description = "处理状态 0待处理 1处理中 2已解决 3已关闭")
    private Integer status;

    private String replyContent;

    private Long replyMemberId;

    @Schema(description = "处理人（后台员工）姓名")
    private String replyEmployeeName;

    private LocalDateTime replyTime;

    private LocalDateTime createTime;
}
