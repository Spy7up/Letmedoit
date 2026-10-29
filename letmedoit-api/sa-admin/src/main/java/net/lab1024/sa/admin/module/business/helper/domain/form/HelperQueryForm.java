package net.lab1024.sa.admin.module.business.helper.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;

import java.time.LocalDate;

/**
 * 帮手关系查询
 *
 * @Author 1024创新实验室
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "帮手关系查询")
public class HelperQueryForm extends PageParam {

    @Schema(description = "会员ID：查看该会员的帮手列表")
    private Long memberId;

    @Schema(description = "关键字：双方昵称 / 邀请码")
    private String searchWord;

    @Schema(description = "建立开始日期，含当天")
    private LocalDate beginDate;

    @Schema(description = "建立结束日期，含当天")
    private LocalDate endDate;
}
