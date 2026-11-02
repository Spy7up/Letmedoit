package net.letmedoit.sa.admin.module.system.role.domain.vo;

import lombok.Data;

/**
 * 角色的员工
 *
 * @author letmedoit
 */
@Data
public class RoleEmployeeVO {

    private Long roleId;

    private Long employeeId;

    private String roleName;
}
