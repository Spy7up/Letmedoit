package net.letmedoit.sa.admin.module.system.role.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import net.letmedoit.sa.base.common.domain.PageParam;

/**
 * 角色 查询
 *
 * @author letmedoit
 */
@Data
public class RoleQueryForm extends PageParam {

    @Schema(description = "角色名称")
    private String roleName;

    @Schema(description = "角色id")
    private String roleId;
}
