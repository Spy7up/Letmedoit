package net.letmedoit.sa.admin.module.business.member.domain.vo;

import lombok.Data;

/**
 * 会员单日完成统计
 *
 * @author letmedoit
 */
@Data
public class MemberDayStatVO {

    private String statDate;

    private Long completedCount;

    private Long onTimeCount;
}
