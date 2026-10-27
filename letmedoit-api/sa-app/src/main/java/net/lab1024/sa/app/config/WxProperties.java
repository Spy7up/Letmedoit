package net.lab1024.sa.app.config;

import jakarta.annotation.PostConstruct;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 微信小程序配置
 * <p>
 * 注意：appid / secret 只从环境变量注入，禁止写入代码仓库
 *
 * @author smart-admin
 */
@Slf4j
@Data
@Component
@ConfigurationProperties(prefix = "wx.miniapp")
public class WxProperties {

    /**
     * 小程序 appid
     */
    private String appid;

    /**
     * 小程序 secret
     */
    private String secret;

    /**
     * 本地无凭证时开启，用假 openid 跑通链路；生产必须为 false
     */
    private boolean mock = false;

    /**
     * 调用微信接口的超时时间（毫秒）
     */
    private int timeout = 5000;

    /**
     * 内容安全检测配置
     */
    private ContentCheck contentCheck = new ContentCheck();

    /**
     * 内容安全（审核硬要求：UGC 输入与图片必须过安全检测）
     */
    @Data
    public static class ContentCheck {

        /**
         * 是否启用。生产必须 true；关掉只用于临时排障
         */
        private boolean enabled = true;

        /**
         * 微信接口异常时是否放行
         * <p>
         * true：微信接口抖动时不阻塞用户发任务（默认）
         * false：任何异常都拒绝提交（更严，但微信侧一抖就没人能发任务）
         */
        private boolean failOpen = true;

        /**
         * 消息推送 Token，与微信后台「开发管理 - 消息推送」里填的一致
         */
        private String pushToken;

        /**
         * 文本场景：1 资料；2 评论；3 论坛；4 社交日志
         * <p>
         * 任务标题/内容属于用户发布的动态类文本，用 4。
         */
        private int textScene = 4;

        /**
         * 图片场景，口径同上
         */
        private int imageScene = 4;

        /**
         * 头像属于「资料」场景
         */
        private int avatarScene = 1;

        /**
         * 异步图片检测超过多少分钟没收到推送就按超时处理
         */
        private int pendingTimeoutMinutes = 35;
    }

    /**
     * 内容安全是否生效
     * <p>
     * 只看开关，不看 mock：mock 模式下也走完整链路（WxApiService 内部返回假结果），
     * 这样本地自检能覆盖「检测记录落库」这段逻辑，不用连真微信。
     */
    public boolean isContentCheckActive() {
        return contentCheck != null && contentCheck.isEnabled();
    }

    @PostConstruct
    public void check() {
        if (mock) {
            log.warn("【微信小程序】mock 模式已开启，不会真实调用微信接口，请勿在生产环境使用！");
            return;
        }
        if (!StringUtils.hasText(appid) || !StringUtils.hasText(secret)) {
            throw new IllegalStateException("wx.miniapp.appid / wx.miniapp.secret 未配置，请在环境变量中注入（本地开发可设置 wx.miniapp.mock=true）");
        }
        if (!isContentCheckActive()) {
            log.warn("【内容安全】检测开关已关闭（wx.miniapp.content-check.enabled=false），UGC 内容不会被检测，小程序审核会不通过！");
        }
        if (isContentCheckActive() && !StringUtils.hasText(contentCheck.getPushToken())) {
            log.warn("【内容安全】wx.miniapp.content-check.push-token 未配置，图片异步检测结果的推送无法验签");
        }
    }
}
