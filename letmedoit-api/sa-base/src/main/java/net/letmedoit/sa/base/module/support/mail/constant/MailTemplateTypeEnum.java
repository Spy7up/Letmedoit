package net.letmedoit.sa.base.module.support.mail.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.letmedoit.sa.base.common.enumeration.BaseEnum;

/**
 * 邮件模板类型
 *
 * @author letmedoit
 */

@Getter
@AllArgsConstructor
public enum MailTemplateTypeEnum implements BaseEnum {

    STRING("string", "字符串替代器"),

    FREEMARKER("freemarker", "freemarker模板引擎");

    private String value;

    private String desc;


}