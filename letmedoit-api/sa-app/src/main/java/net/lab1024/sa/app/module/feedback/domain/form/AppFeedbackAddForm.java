package net.lab1024.sa.app.module.feedback.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import net.lab1024.sa.app.module.feedback.constant.FeedbackTypeEnum;
import net.lab1024.sa.base.common.swagger.SchemaEnum;
import net.lab1024.sa.base.common.validator.enumeration.CheckEnum;
import org.hibernate.validator.constraints.Length;

import java.util.List;

/**
 * 提交问题与反馈
 *
 * @author letmedoit
 */
@Data
@Schema(description = "提交问题与反馈")
public class AppFeedbackAddForm {

    @Schema(description = "反馈类型 1功能建议 2使用问题 3内容违规 4其他",
            requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    @SchemaEnum(desc = "反馈类型", value = FeedbackTypeEnum.class)
    @NotNull(message = "选个反馈类型吧")
    @CheckEnum(value = FeedbackTypeEnum.class, message = "反馈类型不对")
    private Integer type;

    @Schema(description = "反馈内容", requiredMode = Schema.RequiredMode.REQUIRED,
            example = "完成任务后图片没有显示出来")
    @NotBlank(message = "说说遇到的情况吧")
    @Length(max = 500, message = "反馈内容最多 500 个字")
    private String content;

    @Schema(description = "反馈图片，公网 http(s) 地址，最多 3 张，选填")
    @Size(max = 3, message = "最多 3 张图")
    private List<String> images;

    @Schema(description = "联系方式，选填，方便后台回复")
    @Length(max = 64, message = "联系方式最多 64 个字")
    private String contact;
}
