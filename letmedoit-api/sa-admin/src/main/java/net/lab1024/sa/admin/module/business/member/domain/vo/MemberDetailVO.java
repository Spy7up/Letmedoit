package net.lab1024.sa.admin.module.business.member.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * 会员详情
 *
 * @Author 1024创新实验室
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "会员详情")
public class MemberDetailVO extends MemberVO {

    @Schema(description = "待处理的帮手申请数（收到的）")
    private Long pendingHelperRequestCount;

    @Schema(description = "帮手列表，最多 50 条")
    private List<MemberHelperVO> helperList;

    @Schema(description = "最近任务，最多 20 条")
    private List<MemberTaskVO> taskList;

    @Schema(description = "近 14 天完成趋势")
    private List<MemberDayStatVO> dayStatList;
}
