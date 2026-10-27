package net.lab1024.sa.app.config;

import jakarta.annotation.Resource;
import net.lab1024.sa.app.interceptor.AppInterceptor;
import net.lab1024.sa.base.config.SwaggerConfig;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 小程序端 web 配置
 *
 * @author smart-admin
 */
@Configuration
public class AppMvcConfig implements WebMvcConfigurer {

    /**
     * 免登录接口：微信服务器直接回调，靠签名（wx.miniapp.content-check.push-token）校验身份，
     * 不走小程序 token。少配一条，图片违规结果就永远收不到。
     */
    private static final String WX_PUSH_PATH = "/api/wx/push";

    /**
     * 协议接口免登录：登录页就要展示协议版本、点进去要能读全文，
     * 那时候还没有 token。写正文的接口（/agree）仍然要登录。
     */
    private static final String[] AGREEMENT_PUBLIC_PATHS = {
            "/api/agreement/current",
            "/api/agreement/detail"
    };

    /**
     * 版本接口免登录：登录页也可能展示版本号，且版本号不属于用户数据。
     * 版本由后台统一维护，见 docs/版本管理.md。
     */
    private static final String[] VERSION_PUBLIC_PATHS = {
            "/api/version/current"
    };

    @Resource
    private AppInterceptor appInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 只拦截 /api/**：所有小程序业务接口强制校验 token
        registry.addInterceptor(appInterceptor)
                .excludePathPatterns(SwaggerConfig.SWAGGER_WHITELIST)
                .excludePathPatterns(WX_PUSH_PATH)
                .excludePathPatterns(AGREEMENT_PUBLIC_PATHS)
                .excludePathPatterns(VERSION_PUBLIC_PATHS)
                .addPathPatterns("/api/**");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("doc.html").addResourceLocations("classpath:/META-INF/resources/");
        registry.addResourceHandler("/webjars/**").addResourceLocations("classpath:/META-INF/resources/webjars/");
    }
}
