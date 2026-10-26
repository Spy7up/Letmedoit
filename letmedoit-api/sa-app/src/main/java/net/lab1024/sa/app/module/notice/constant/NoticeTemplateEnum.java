package net.lab1024.sa.app.module.notice.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 站内通知模板
 * <p>
 * templateKey 与小程序端消息中心保持一致，决定通知卡片上的标题与字段结构。
 * <p>
 * 通知只写 t_task_notice（站内信），由小程序消息中心展示，不依赖任何外部推送通道。
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum NoticeTemplateEnum {

    /**
     * 参与者收：有人给你派活（或把你加进任务）
     */
    TASK_ASSIGNED("TASK_ASSIGNED", "任务委托通知"),

    /**
     * 参与者收：快到截止时间了
     */
    TASK_REMIND("TASK_REMIND", "任务到期提醒"),

    /**
     * 创建者收：有人接受了任务
     */
    TASK_ACCEPTED("TASK_ACCEPTED", "任务被接受"),

    /**
     * 创建者收：有人拒绝了任务
     */
    TASK_REJECTED("TASK_REJECTED", "任务被拒绝"),

    /**
     * 创建者收：有人完成了自己那份
     */
    TASK_COMPLETED("TASK_COMPLETED", "任务完成通知"),

    /**
     * 创建者收：过了截止时间还没全部做完
     */
    TASK_OVERDUE("TASK_OVERDUE", "任务已逾期"),

    /**
     * 创建者 + 全体参与者：所有人都做完了
     */
    TASK_ALL_DONE("TASK_ALL_DONE", "全员完成通知"),

    TASK_START("TASK_START", "任务开始通知"),

    TASK_EDITED("TASK_EDITED", "任务变更通知"),

    TASK_CANCELLED("TASK_CANCELLED", "任务取消通知"),

    /**
     * 委托人收：图片被内容安全判定违规，已自动移除
     */
    CONTENT_TAKEDOWN("CONTENT_TAKEDOWN", "内容安全处理通知");

    private final String key;

    private final String title;

    public static NoticeTemplateEnum getByKey(String key) {
        for (NoticeTemplateEnum item : values()) {
            if (item.getKey().equals(key)) {
                return item;
            }
        }
        return null;
    }
}
