package net.lab1024.sa.admin.module.business.version.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.lab1024.sa.base.common.enumeration.BaseEnum;

/**
 * 版本所属端
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum AppVersionPlatformEnum implements BaseEnum {

    MINIAPP("miniapp", "微信小程序");

    private final String value;

    private final String desc;

    public static AppVersionPlatformEnum getByValue(String value) {
        for (AppVersionPlatformEnum item : values()) {
            if (item.getValue().equals(value)) {
                return item;
            }
        }
        return null;
    }
}
