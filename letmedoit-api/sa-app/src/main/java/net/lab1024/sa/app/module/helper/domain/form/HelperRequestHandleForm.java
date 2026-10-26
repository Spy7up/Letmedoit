package net.lab1024.sa.app.module.helper.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 处理帮手申请
 *
 * @author letmedoit
 */
@Data
@Schema(description = "处理帮手申请")
public class HelperRequestHandleForm {

    @Schema(description = "申请ID", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "申请ID不能为空")
    private Long requestId;
}
