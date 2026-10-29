package net.lab1024.sa.admin.module.business.feedback.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;

import java.time.LocalDate;

/**
 * 小程序反馈查询
 *
 * @Author 1024创新实验室
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "小程序反馈查询")
public class AppFeedbackQueryForm extends PageParam {

    @Schema(description = "关键字：反馈内容 / 会员昵称 / 反馈ID")
    private String searchWord;

    @Schema(description = "反馈类型 1功能建议 2使用问题 3内容违规 4其他")
    private Integer type;

    @Schema(description = "处理状态 0待处理 1处理中 2已解决 3已关闭")
    private Integer status;

    @Schema(description = "提交会员ID")
    private Long memberId;

    @Schema(description = "提交开始日期，含当天")
    private LocalDate beginDate;

    @Schema(description = "提交结束日期，含当天")
    private LocalDate endDate;
}
