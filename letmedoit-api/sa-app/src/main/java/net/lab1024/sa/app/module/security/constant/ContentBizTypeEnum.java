package net.lab1024.sa.app.module.security.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 内容检测的业务来源
 * <p>
 * 决定违规后往哪儿下架：头像清空、任务图从任务里剔除。
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum ContentBizTypeEnum {

    AVATAR("avatar", "头像"),

    TASK_IMAGE("task_image", "任务附图"),

    TASK_PROOF("task_proof", "完成凭证");

    private final String value;

    private final String desc;

    public static ContentBizTypeEnum getByValue(String value) {
        for (ContentBizTypeEnum item : values()) {
            if (item.getValue().equals(value)) {
                return item;
            }
        }
        return null;
    }
}
