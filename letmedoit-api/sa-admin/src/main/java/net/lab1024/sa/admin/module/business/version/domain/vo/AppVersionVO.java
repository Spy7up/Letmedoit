package net.lab1024.sa.admin.module.business.version.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 版本列表项
 *
 * @author letmedoit
 */
@Data
@Schema(description = "版本列表项")
public class AppVersionVO {

    private Long versionId;

    private String appType;

    private String version;

    private String versionLabel;

    private String releaseNote;

    private LocalDateTime releaseTime;

    private String minBaseLib;

    private Boolean forceUpdateFlag;

    private Boolean currentFlag;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
