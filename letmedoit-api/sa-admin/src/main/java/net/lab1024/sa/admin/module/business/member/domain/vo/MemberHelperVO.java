package net.lab1024.sa.admin.module.business.member.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 会员的帮手
 *
 * @Author 1024创新实验室
 */
@Data
public class MemberHelperVO {

    private Long helperMemberId;

    private String nickname;

    private String avatar;

    private String inviteCode;

    private String remark;

    private LocalDateTime createTime;
}
