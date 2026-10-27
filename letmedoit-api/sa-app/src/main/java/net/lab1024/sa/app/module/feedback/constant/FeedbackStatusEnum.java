package net.lab1024.sa.app.module.feedback.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.lab1024.sa.base.common.enumeration.BaseEnum;

/**
 * 反馈处理状态（t_app_feedback.status）
 * <p>
 * 小程序端不展示这个状态（用户只关心「有没有人回我」），
 * 它是给后台客服工作台用的流转标记，本期只落库、不做后台界面。
 * <p>
 * 文案以数据字典 FEEDBACK_STATUS 为准，desc 仅兜底。
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum FeedbackStatusEnum implements BaseEnum {

    PENDING(0, "待处理"),

    PROCESSING(1, "处理中"),

    RESOLVED(2, "已解决"),

    CLOSED(3, "已关闭");

    private final Integer value;

    private final String desc;

    public static FeedbackStatusEnum getByValue(Integer value) {
        if (value == null) {
            return null;
        }
        for (FeedbackStatusEnum item : values()) {
            if (item.getValue().equals(value)) {
                return item;
            }
        }
        return null;
    }
}
