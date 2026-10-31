package net.lab1024.sa.admin.module.business.version.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 新增版本
 *
 * @author letmedoit
 */
@Data
@Schema(description = "新增版本")
public class AppVersionAddForm {

    @NotBlank(message = "端类型不能为空")
    @Size(max = 16, message = "端类型长度不能超过16个字符")
    private String appType;

    @NotBlank(message = "版本号不能为空")
    @Size(max = 32, message = "版本号长度不能超过32个字符")
    @Pattern(regexp = "^\\d+\\.\\d+\\.\\d+$", message = "版本号格式应为 x.y.z，例如 1.1.0")
    private String version;

    @Size(max = 32, message = "展示版本号长度不能超过32个字符")
    private String versionLabel;

    @Size(max = 500, message = "更新说明长度不能超过500个字符")
    private String releaseNote;

    @Schema(description = "发布时间；发布时仍为空则取发布操作时间")
    private LocalDateTime releaseTime;

    @Size(max = 16, message = "最低基础库长度不能超过16个字符")
    private String minBaseLib;

    @NotNull(message = "强制更新标记不能为空")
    private Boolean forceUpdateFlag;
}
