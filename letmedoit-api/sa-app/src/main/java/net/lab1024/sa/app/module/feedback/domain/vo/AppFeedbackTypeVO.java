package net.lab1024.sa.app.module.feedback.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 反馈类型（前端 chips 直接渲染）
 *
 * @author letmedoit
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "反馈类型")
public class AppFeedbackTypeVO {

    @Schema(description = "类型值，提交时原样回传")
    private Integer value;

    @Schema(description = "类型文案")
    private String label;
}
