package net.lab1024.sa.admin.module.business.task.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;

import java.time.LocalDate;

/**
 * 任务查询
 *
 * @Author 1024创新实验室
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "任务查询")
public class TaskQueryForm extends PageParam {

    @Schema(description = "关键字：任务标题 / 委托人昵称 / 任务ID")
    private String searchWord;

    @Schema(description = "聚合状态 0预约中 1待接受 2进行中 3已完成 4已拒绝 5已撤回")
    private Integer status;

    @Schema(description = "委托人会员ID")
    private Long creatorId;

    @Schema(description = "只看逾期：未结束且已过截止时间")
    private Boolean overdueFlag;

    @Schema(description = "创建开始日期，含当天")
    private LocalDate beginDate;

    @Schema(description = "创建结束日期，含当天")
    private LocalDate endDate;
}
