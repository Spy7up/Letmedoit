package net.lab1024.sa.app.module.version.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.lab1024.sa.base.common.enumeration.BaseEnum;

/**
 * 版本所属端（t_app_version.app_type）
 * <p>
 * 现在只有微信小程序；表里留这一列，是为了将来加 H5 / App 时不用改表结构，
 * 也不会出现「小程序的 1.1.0」被 H5 读到的情况。
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum VersionPlatformEnum implements BaseEnum {

    MINIAPP("miniapp", "微信小程序");

    private final String value;

    private final String desc;

    public static VersionPlatformEnum getByValue(String value) {
        for (VersionPlatformEnum item : values()) {
            if (item.getValue().equals(value)) {
                return item;
            }
        }
        return null;
    }
}
