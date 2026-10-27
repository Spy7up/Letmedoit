package net.lab1024.sa.app.module.feedback.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.lab1024.sa.base.common.enumeration.BaseEnum;

/**
 * 反馈类型（t_app_feedback.type）
 * <p>
 * 展示文案以数据字典 FEEDBACK_TYPE 为准（AppDictCode.FEEDBACK_TYPE），
 * 这里的 desc 只在字典未初始化时兜底。
 * <p>
 * 分类的意义在于后台分派：内容违规要当天处理，功能建议可以排期。
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum FeedbackTypeEnum implements BaseEnum {

    FEATURE(1, "功能建议"),

    BUG(2, "使用问题"),

    CONTENT(3, "内容违规"),

    OTHER(4, "其他");

    private final Integer value;

    private final String desc;

    public static FeedbackTypeEnum getByValue(Integer value) {
        if (value == null) {
            return null;
        }
        for (FeedbackTypeEnum item : values()) {
            if (item.getValue().equals(value)) {
                return item;
            }
        }
        return null;
    }
}
