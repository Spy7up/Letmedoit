package net.lab1024.sa.app.module.member.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 小程序登录表单
 *
 * @author smart-admin
 */
@Data
public class WxLoginForm {

    @Schema(description = "wx.login 返回的 code（5 分钟有效，一次性）")
    @NotBlank(message = "code 不能为空")
    private String code;

    /**
     * 微信头像昵称：登录时前端用 getUserProfile / chooseAvatar 拿到的资料。
     * 用户拒绝授权时为空，后端会生成「用户XXXX」兜底昵称。
     */
    @Schema(description = "微信昵称（可为空）")
    private String nickname;

    @Schema(description = "微信头像地址（可为空）")
    private String avatar;

    /**
     * 用户勾选同意的协议版本（来自 /api/agreement/current 的 version）
     * <p>
     * 必填：不传就是没同意，直接拒绝登录。审核要求「必须同意后才能使用」，
     * 只在前端做个勾选框没有任何约束力。
     */
    @Schema(description = "已同意的协议版本，来自 /api/agreement/current", requiredMode = Schema.RequiredMode.REQUIRED)
    private String agreementVersion;
}
