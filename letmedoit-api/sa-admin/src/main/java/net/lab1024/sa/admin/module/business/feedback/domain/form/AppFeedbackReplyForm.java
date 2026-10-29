package net.lab1024.sa.admin.module.business.feedback.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 小程序反馈回复
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "小程序反馈回复")
public class AppFeedbackReplyForm {

    @NotNull(message = "反馈ID不能为空")
    @Schema(description = "反馈ID")
    private Long feedbackId;

    @NotNull(message = "处理状态不能为空")
    @Schema(description = "目标状态：1处理中 2已解决 3已关闭")
    private Integer status;

    @Size(max = 500, message = "回复内容最多500字")
    @Schema(description = "回复内容，标记已解决时必填")
    private String replyContent;
}
