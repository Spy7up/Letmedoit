package net.lab1024.sa.app.module.helper.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

/**
 * 发起帮手申请
 *
 * @author letmedoit
 */
@Data
@Schema(description = "发起帮手申请")
public class HelperRequestAddForm {

    @Schema(description = "对方会员ID", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "请选择帮手")
    private Long toMemberId;

    @Schema(description = "附言", example = "我是楼下老李")
    @Length(max = 100, message = "附言最多 100 个字")
    private String applyMessage;
}
