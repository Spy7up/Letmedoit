package net.letmedoit.sa.admin.module.system.role.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 选择角色
 *
 * @author letmedoit
 */
@Data
public class RoleSelectedVO extends RoleVO {

    @Schema(description = "角色名称")
    private Boolean selected;
}
