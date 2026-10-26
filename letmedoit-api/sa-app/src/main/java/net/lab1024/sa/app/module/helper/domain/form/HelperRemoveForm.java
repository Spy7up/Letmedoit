package net.lab1024.sa.app.module.helper.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 解除帮手
 *
 * @author letmedoit
 */
@Data
@Schema(description = "解除帮手")
public class HelperRemoveForm {

    @Schema(description = "帮手关系ID", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "帮手关系ID不能为空")
    private Long helperId;
}
