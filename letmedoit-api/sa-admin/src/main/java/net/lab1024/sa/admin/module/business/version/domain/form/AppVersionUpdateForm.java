package net.lab1024.sa.admin.module.business.version.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 修改版本
 *
 * @author letmedoit
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "修改版本")
public class AppVersionUpdateForm extends AppVersionAddForm {

    @NotNull(message = "版本ID不能为空")
    private Long versionId;
}
