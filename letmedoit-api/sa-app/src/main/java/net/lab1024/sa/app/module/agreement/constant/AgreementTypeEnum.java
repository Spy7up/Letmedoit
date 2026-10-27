package net.lab1024.sa.app.module.agreement.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 协议类型
 * <p>
 * 登录前必须两类都同意，缺一不可；记录也按类型分开存，
 * 便于将来单独更新某一篇时精确判断「哪一份没同意」。
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum AgreementTypeEnum {

    USER("user", "用户协议"),

    PRIVACY("privacy", "隐私政策");

    private final String value;

    private final String desc;

    public static AgreementTypeEnum getByValue(String value) {
        for (AgreementTypeEnum item : values()) {
            if (item.getValue().equals(value)) {
                return item;
            }
        }
        return null;
    }
}
