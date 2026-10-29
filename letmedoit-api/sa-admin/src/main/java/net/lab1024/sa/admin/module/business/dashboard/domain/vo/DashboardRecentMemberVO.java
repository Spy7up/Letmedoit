package net.lab1024.sa.admin.module.business.dashboard.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Schema(description = "最新注册会员")
public class DashboardRecentMemberVO {

    private Long memberId;

    private String nickname;

    private String avatar;

    private LocalDateTime createTime;

    private LocalDateTime lastLoginTime;
}
