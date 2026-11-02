package net.letmedoit.sa.base.common.domain;


import lombok.AllArgsConstructor;
import lombok.Getter;
import net.letmedoit.sa.base.common.enumeration.SystemEnvironmentEnum;

/**
 * 系统环境
 *
 * @author letmedoit
 */
@AllArgsConstructor
@Getter
public class SystemEnvironment {

    /**
     * 是否位生产环境
     */
    private boolean isProd;

    /**
     * 项目名称
     */
    private String projectName;

    /**
     * 当前环境
     */
    private SystemEnvironmentEnum currentEnvironment;
}
