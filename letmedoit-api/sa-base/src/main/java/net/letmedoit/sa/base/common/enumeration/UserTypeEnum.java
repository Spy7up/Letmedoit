package net.letmedoit.sa.base.common.enumeration;

/**
 * 用户类型
 *
 * @author letmedoit
 */
public enum UserTypeEnum implements BaseEnum {

    /**
     * 管理端 员工用户
     */
    ADMIN_EMPLOYEE(1, "员工"),

    /**
     * 小程序 C 端会员
     */
    WX_MEMBER(2, "小程序会员");

    private Integer type;

    private String desc;

    UserTypeEnum(Integer type, String desc) {
        this.type = type;
        this.desc = desc;
    }

    @Override
    public Integer getValue() {
        return type;
    }

    @Override
    public String getDesc() {
        return desc;
    }
}
