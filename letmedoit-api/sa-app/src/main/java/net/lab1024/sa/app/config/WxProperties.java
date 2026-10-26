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

    @PostConstruct
    public void check() {
        if (mock) {
            log.warn("【微信小程序】mock 模式已开启，不会真实调用微信接口，请勿在生产环境使用！");
            return;
        }
        if (!StringUtils.hasText(appid) || !StringUtils.hasText(secret)) {
            throw new IllegalStateException("wx.miniapp.appid / wx.miniapp.secret 未配置，请在环境变量中注入（本地开发可设置 wx.miniapp.mock=true）");
        }
    }
}
