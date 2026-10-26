package net.lab1024.sa.app.module.security.controller;

import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.SecureUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.config.WxProperties;
import net.lab1024.sa.app.module.security.service.ContentSecurityService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;

/**
 * 微信消息推送入口
 * <p>
 * 只承担一件事：接收图片异步检测结果（Event = wxa_media_check）。
 * 微信要求该地址免登录可访问，且必须在 5 秒内原样返回 success，否则会重试。
 * <p>
 * 后台配置（微信公众平台 - 开发管理 - 消息推送）：
 * <ul>
 *     <li>URL：https://你的域名/api/wx/push</li>
 *     <li>Token：与 wx.miniapp.content-check.push-token 一致</li>
 *     <li>数据格式：**JSON**（不是 XML）</li>
 *     <li>消息加解密方式：**明文模式**（本项目只实现了明文 + 验签）</li>
 * </ul>
 *
 * @author letmedoit
 */
@Slf4j
@RestController
@RequestMapping("/api/wx")
@Tag(name = "小程序-微信消息推送")
public class WxMessagePushController {

    /**
     * 图片异步检测事件名
     */
    private static final String EVENT_MEDIA_CHECK = "wxa_media_check";

    @Resource
    private WxProperties wxProperties;

    @Resource
    private ContentSecurityService contentSecurityService;

    /**
     * 微信后台保存配置时的连通性校验：验签通过就原样回 echostr
     */
    @GetMapping("/push")
    @Operation(summary = "消息推送地址校验 @author letmedoit")
    public String verify(@RequestParam(required = false) String signature,
                         @RequestParam(required = false) String timestamp,
                         @RequestParam(required = false) String nonce,
                         @RequestParam(required = false) String echostr) {
        if (!checkSignature(signature, timestamp, nonce)) {
            return "invalid signature";
        }
        log.info("微信消息推送地址校验通过");
        return StrUtil.blankToDefault(echostr, "");
    }

    /**
     * 接收事件推送
     */
    @PostMapping("/push")
    @Operation(summary = "接收微信事件推送 @author letmedoit")
    public String receive(@RequestParam(required = false) String signature,
                          @RequestParam(required = false) String timestamp,
                          @RequestParam(required = false) String nonce,
                          @RequestBody(required = false) String body) {
        if (!checkSignature(signature, timestamp, nonce)) {
            return "invalid signature";
        }
        if (StrUtil.isBlank(body)) {
            return "success";
        }
        try {
            JSONObject json = JSONUtil.parseObj(body);
            String event = json.getStr("Event");
            log.info("收到微信推送, MsgType={}, Event={}", json.getStr("MsgType"), event);
            if (EVENT_MEDIA_CHECK.equalsIgnoreCase(event)) {
                contentSecurityService.handleMediaCheckEvent(json);
            }
            return "success";
        } catch (Exception e) {
            // 解析失败也回 success：否则微信会持续重试同一条坏数据
            log.error("处理微信推送失败, body={}", body, e);
            return "success";
        }
    }

    /**
     * 微信签名算法：sha1(字典序拼接 token、timestamp、nonce)
     * <p>
     * 失败时把「本地按当前 Token 算出的签名」也打出来，一眼就能判断是不是
     * 微信后台填的 Token 与服务器上的 {@code WX_PUSH_TOKEN} 不一致 —— 这是最常见的坑。
     */
    private boolean checkSignature(String signature, String timestamp, String nonce) {
        String token = wxProperties.getContentCheck() == null
                ? null : wxProperties.getContentCheck().getPushToken();
        if (StrUtil.isBlank(token)) {
            log.error("微信消息推送验签失败：wx.miniapp.content-check.push-token 为空。"
                    + "请在服务器 .env / 环境变量里注入 WX_PUSH_TOKEN（与微信后台消息推送的 Token 一致）后重启后端");
            return false;
        }
        if (StrUtil.isBlank(signature) || StrUtil.isBlank(timestamp) || StrUtil.isBlank(nonce)) {
            log.error("微信消息推送验签失败：参数缺失, signature={}, timestamp={}, nonce={}",
                    signature, timestamp, nonce);
            return false;
        }
        String[] arr = {token, timestamp, nonce};
        Arrays.sort(arr);
        String expected = SecureUtil.sha1(arr[0] + arr[1] + arr[2]);
        if (!expected.equalsIgnoreCase(signature)) {
            log.warn("微信消息推送验签失败：Token 不一致。收到 signature={}, 当前 Token(长度 {}) 算出={}, timestamp={}, nonce={}。"
                            + "请核对微信后台「消息推送 - Token」与 WX_PUSH_TOKEN 是否完全相同",
                    signature, token.length(), expected, timestamp, nonce);
            return false;
        }
        return true;
    }
}
