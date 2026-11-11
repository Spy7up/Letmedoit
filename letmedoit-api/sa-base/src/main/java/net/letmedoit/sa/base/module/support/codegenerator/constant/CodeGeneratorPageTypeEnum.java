package net.letmedoit.sa.base.module.support.codegenerator.constant;

import net.letmedoit.sa.base.common.enumeration.BaseEnum;

/**
 * 页面类型
 *
 * @author letmedoit
 */
public enum CodeGeneratorPageTypeEnum implements BaseEnum {

    MODAL("modal", "弹窗"),
    DRAWER("drawer", "抽屉"),
    PAGE("page", "新页面");

    private String value;

    private String desc;

    CodeGeneratorPageTypeEnum(String value, String desc) {
        this.value = value;
        this.desc = desc;
    }

    @Override
    public Object getValue() {
        return value;
    }

    @Override
    public String getDesc() {
        return desc;
    }
}
