package net.lab1024.sa.admin.module.business.member.domain.vo;

import lombok.Data;

/**
 * 会员单日完成统计
 *
 * @Author 1024创新实验室
 */
@Data
public class MemberDayStatVO {

    private String statDate;

    private Long completedCount;

    private Long onTimeCount;
}
