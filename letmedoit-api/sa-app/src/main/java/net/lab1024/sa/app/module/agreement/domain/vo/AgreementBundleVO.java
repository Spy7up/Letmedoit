package net.lab1024.sa.app.module.agreement.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 登录前需要的协议摘要
 * <p>
 * 只带元信息不带正文：登录页只需要版本号做校验和展示，
 * 正文等用户点进去再按 type 单独取，避免登录页白拉十几 KB。
 *
 * @author letmedoit
 */
@Data
@Schema(description = "协议摘要")
public class AgreementBundleVO {

    @Schema(description = "用户协议")
    private AgreementSummary userAgreement;

    @Schema(description = "隐私政策")
    private AgreementSummary privacyPolicy;

    /**
     * 组合版本号，前端原样回传即可
     * <p>
     * 两篇协议版本可能不同（比如只改了隐私政策），所以不能只用一个号，
     * 但前端也没必要自己拼，直接把这个串存下来回传最省事。
     */
    @Schema(description = "组合版本号，登录时原样回传")
    private String version;

    @Data
    @Schema(description = "协议摘要项")
    public static class AgreementSummary {

        @Schema(description = "类型")
        private String type;

        @Schema(description = "标题")
        private String title;

        @Schema(description = "版本号")
        private String version;

        @Schema(description = "生效日期 yyyy-MM-dd")
        private String effectiveDate;
    }
}
