package net.lab1024.sa.app.module.version.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 当前版本（小程序所有版本文案的唯一来源）
 *
 * @author letmedoit
 */
@Data
@Schema(description = "当前版本")
public class AppVersionVO {

    @Schema(description = "端类型 miniapp")
    private String appType;

    @Schema(description = "版本号，如 1.1.0")
    private String version;

    @Schema(description = "展示用版本号，如 v1.1.0")
    private String versionLabel;

    @Schema(description = "更新说明")
    private String releaseNote;

    @Schema(description = "发布时间")
    private LocalDateTime releaseTime;

    @Schema(description = "最低基础库版本（预留）")
    private String minBaseLib;

    @Schema(description = "是否强制更新（预留）")
    private Boolean forceUpdateFlag;
}
