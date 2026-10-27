package net.lab1024.sa.app.module.security.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;
import net.lab1024.sa.base.common.enumeration.BaseEnum;

/**
 * 内容安全检测状态
 *
 * @author letmedoit
 */
@Getter
@AllArgsConstructor
public enum ContentCheckStatusEnum implements BaseEnum {

    /**
     * 已提交微信异步接口，等推送结果
     */
    PENDING(0, "审核中"),

    /**
     * 检测通过
     */
    PASS(1, "通过"),

    /**
     * 检测违规，已下架
     */
    RISKY(2, "违规"),

    /**
     * 调用失败或超时未回，按配置决定放行还是拦截
     */
    FAIL(3, "检测失败");

    private final Integer value;

    private final String desc;
}
