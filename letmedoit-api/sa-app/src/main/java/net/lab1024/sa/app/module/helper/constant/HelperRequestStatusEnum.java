package net.lab1024.sa.app.module.helper.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.lab1024.sa.base.common.enumeration.BaseEnum;

/**
 * 帮手申请状态
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum HelperRequestStatusEnum implements BaseEnum {

    PENDING(0, "待处理"),

    ACCEPTED(1, "已同意"),

    REJECTED(2, "已拒绝");

    private final Integer value;

    private final String desc;
}
