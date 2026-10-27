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

    TASK_PROOF("task_proof", "完成凭证"),

    FEEDBACK_IMAGE("feedback_image", "反馈图片");

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

    /**
     * 上传接口的 bizType → 检测业务类型
     * <p>
     * 上传接口的 bizType 由客户端传，认不出的一律按任务附图处理：
     * 下架时多扫两处不会误伤，漏扫才会把违规图留在线上。
     *
     * @param uploadBizType 上传接口 bizType：avatar / task-image / feedback-image
     * @return 检测业务类型
     */
    public static ContentBizTypeEnum ofUploadBizType(String uploadBizType) {
        if ("avatar".equalsIgnoreCase(uploadBizType)) {
            return AVATAR;
        }
        if ("feedback-image".equalsIgnoreCase(uploadBizType)) {
            return FEEDBACK_IMAGE;
        }
        return TASK_IMAGE;
    }
}
