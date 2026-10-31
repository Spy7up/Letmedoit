package net.lab1024.sa.admin.module.business.version.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 发布版本
 *
 * @author letmedoit
 */
@Data
@Schema(description = "发布版本")
public class AppVersionPublishForm {

    @NotNull(message = "版本ID不能为空")
    private Long versionId;
}
