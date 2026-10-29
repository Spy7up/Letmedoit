package net.lab1024.sa.admin.module.business.member.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;

import java.time.LocalDate;

/**
 * 会员查询
 *
 * @Author 1024创新实验室
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "会员查询")
public class MemberQueryForm extends PageParam {

    @Schema(description = "关键字：昵称 / 邀请码 / 会员ID")
    private String searchWord;

    @Schema(description = "是否禁用")
    private Boolean disabledFlag;

    @Schema(description = "注册开始日期，含当天")
    private LocalDate beginDate;

    @Schema(description = "注册结束日期，含当天")
    private LocalDate endDate;
}
