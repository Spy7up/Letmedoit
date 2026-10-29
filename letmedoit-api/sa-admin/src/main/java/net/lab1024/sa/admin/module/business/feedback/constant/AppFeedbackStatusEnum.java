package net.lab1024.sa.admin.module.business.feedback.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;
import java.util.List;

/**
 * 小程序反馈处理状态
 * 0待处理 1处理中 2已解决 3已关闭；已关闭为终态
 *
 * @Author 1024创新实验室
 */
@Getter
@AllArgsConstructor
public enum AppFeedbackStatusEnum {

    PENDING(0, "待处理"),
    PROCESSING(1, "处理中"),
    RESOLVED(2, "已解决"),
    CLOSED(3, "已关闭");

    private final Integer value;

    private final String desc;

    public static AppFeedbackStatusEnum getByValue(Integer value) {
        return Arrays.stream(values()).filter(item -> item.value.equals(value)).findFirst().orElse(null);
    }

    /**
     * 允许的状态流转：0→1/2/3，1→2/3，2→3
     */
    public static List<Integer> allowNextStatus(Integer currentStatus) {
        if (PENDING.value.equals(currentStatus)) {
            return List.of(PROCESSING.value, RESOLVED.value, CLOSED.value);
        }
        if (PROCESSING.value.equals(currentStatus)) {
            return List.of(RESOLVED.value, CLOSED.value);
        }
        if (RESOLVED.value.equals(currentStatus)) {
            return List.of(CLOSED.value);
        }
        return List.of();
    }
}
