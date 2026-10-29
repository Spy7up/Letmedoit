package net.lab1024.sa.admin.module.business.helper.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 帮手关系（单方向一行）
 *
 * @Author 1024创新实验室
 */
@Data
@Schema(description = "帮手关系")
public class HelperVO {

    private Long helperId;

    private Long memberId;

    private String memberNickname;

    private String memberInviteCode;

    private Long helperMemberId;

    private String helperNickname;

    private String helperInviteCode;

    @Schema(description = "备注名，覆盖对方昵称展示")
    private String remark;

    private LocalDateTime createTime;
}
