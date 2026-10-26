package net.lab1024.sa.app.module.agreement.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 协议（含正文）
 *
 * @author letmedoit
 */
@Data
@Schema(description = "协议详情")
public class AgreementVO {

    @Schema(description = "类型 user 用户协议 / privacy 隐私政策")
    private String type;

    @Schema(description = "标题")
    private String title;

    @Schema(description = "版本号")
    private String version;

    @Schema(description = "生效时间")
    private LocalDateTime effectiveTime;

    @Schema(description = "正文，纯文本，# 开头为标题行")
    private String content;
}
