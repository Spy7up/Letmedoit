package net.lab1024.sa.app.module.wx;

import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.SecureUtil;
import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.config.WxProperties;
import net.lab1024.sa.app.constant.AppRedisKeyConst;
import net.lab1024.sa.app.module.wx.domain.WxSessionVO;
import net.lab1024.sa.base.common.exception.BusinessException;
import net.lab1024.sa.base.module.support.redis.RedisService;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 微信小程序接口封装
 * <p>
 * 只负责与微信通信，不含业务逻辑；session_key 仅在方法内部使用，不对外暴露
 *
 * @author smart-admin
 */
@Slf4j
@Service
public class WxApiService {

    private static final String URL_CODE2SESSION = "https://api.weixin.qq.com/sns/jscode2session";

    private static final String URL_ACCESS_TOKEN = "https://api.weixin.qq.com/cgi-bin/token";

    private static final String URL_PHONE = "https://api.weixin.qq.com/wxa/business/getuserphonenumber";

    /**
     * 文本内容安全检测（同步）
     */
    private static final String URL_MSG_SEC_CHECK = "https://api.weixin.qq.com/wxa/msg_sec_check";

    /**
     * 图片/音频内容安全检测（异步）
     */
    private static final String URL_MEDIA_CHECK_ASYNC = "https://api.weixin.qq.com/wxa/media_check_async";

    /**
     * 文本检测接口版本号，2.0 固定为 2
     */
    private static final int SEC_CHECK_VERSION = 2;

    /**
     * 文本检测内容长度上限（官方限制 2500 字）
     */
    private static final int MSG_SEC_CHECK_MAX_LENGTH = 2500;

    /**
     * access_token 提前过期时间，避免边界失效
     */
    private static final int TOKEN_EXPIRE_AHEAD_SECONDS = 300;

    /**
     * 微信 access_token 失效错误码
     */
    private static final int ERR_TOKEN_INVALID = 42001;

    /**
     * 内容检测结论：通过
     */
    public static final String SUGGEST_PASS = "pass";

    /**
     * 内容检测结论：疑似（人工复核区间，审核期按不通过处理）
     */
    public static final String SUGGEST_REVIEW = "review";

    /**
     * 内容检测结论：违规
     */
    public static final String SUGGEST_RISKY = "risky";

    @Resource
    private WxProperties wxProperties;

    @Resource
    private RedisService redisService;

    @Resource
    private RedissonClient redissonClient;

    /**
     * code 换 openid
     */
    public WxSessionVO jscode2session(String code) {
        if (wxProperties.isMock()) {
            WxSessionVO mock = new WxSessionVO();
            mock.setOpenId("mock_" + SecureUtil.md5(code));
            mock.setUnionId("mock_union_" + SecureUtil.md5(code));
            log.warn("【mock】jscode2session code={} openId={}", code, mock.getOpenId());
            return mock;
        }

        Map<String, Object> params = new HashMap<>(8);
        params.put("appid", wxProperties.getAppid());
        params.put("secret", wxProperties.getSecret());
        params.put("js_code", code);
        params.put("grant_type", "authorization_code");

        String body = HttpUtil.get(URL_CODE2SESSION, params, wxProperties.getTimeout());
        JSONObject json = parse(body, "code2session");

        int errcode = json.getInt("errcode", 0);
        if (errcode != 0) {
            log.warn("微信 code2session 失败, errcode={}, errmsg={}", errcode, json.getStr("errmsg"));
            throw new BusinessException("微信登录失败，请重试");
        }

        String openId = json.getStr("openid");
        if (StrUtil.isBlank(openId)) {
            throw new BusinessException("微信登录失败，请重试");
        }

        WxSessionVO session = new WxSessionVO();
        session.setOpenId(openId);
        session.setUnionId(json.getStr("unionid"));
        session.setSessionKey(json.getStr("session_key"));
        return session;
    }

    /**
     * 获取接口调用凭证（Redis 缓存 + 分布式锁单飞，防止并发刷新互相顶掉）
     */
    public String getAccessToken() {
        if (wxProperties.isMock()) {
            return "mock_access_token";
        }

        String cached = redisService.get(AppRedisKeyConst.WX_ACCESS_TOKEN);
        if (StrUtil.isNotBlank(cached)) {
            return cached;
        }

        RLock lock = redissonClient.getLock(AppRedisKeyConst.WX_ACCESS_TOKEN_LOCK);
        try {
            if (!lock.tryLock(3, 10, TimeUnit.SECONDS)) {
                throw new BusinessException("微信服务繁忙，请稍后重试");
            }
            // 双重检查
            cached = redisService.get(AppRedisKeyConst.WX_ACCESS_TOKEN);
            if (StrUtil.isNotBlank(cached)) {
                return cached;
            }

            Map<String, Object> params = new HashMap<>(4);
            params.put("grant_type", "client_credential");
            params.put("appid", wxProperties.getAppid());
            params.put("secret", wxProperties.getSecret());

            String body = HttpUtil.get(URL_ACCESS_TOKEN, params, wxProperties.getTimeout());
            JSONObject json = parse(body, "getAccessToken");

            int errcode = json.getInt("errcode", 0);
            if (errcode != 0) {
                log.error("获取微信 access_token 失败, errcode={}, errmsg={}", errcode, json.getStr("errmsg"));
                throw new BusinessException("微信服务异常，请稍后重试");
            }

            String accessToken = json.getStr("access_token");
            long expiresIn = json.getLong("expires_in", 7200L);
            long ttl = Math.max(expiresIn - TOKEN_EXPIRE_AHEAD_SECONDS, 60L);
            redisService.set(AppRedisKeyConst.WX_ACCESS_TOKEN, accessToken, ttl);
            return accessToken;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BusinessException("微信凭证获取被中断，请重试");
        } finally {
            if (lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }

    /**
     * 清除凭证缓存（凭证失效时调用）
     */
    public void clearAccessToken() {
        redisService.delete(AppRedisKeyConst.WX_ACCESS_TOKEN);
    }

    /**
     * 用 getPhoneNumber 的 code 换取手机号（服务端解密，可信）
     *
     * @return 纯手机号（不含区号）
     */
    public String getPhoneNumber(String code) {
        if (wxProperties.isMock()) {
            log.warn("【mock】getPhoneNumber code={} 返回默认手机号", code);
            return "13800000000";
        }

        JSONObject json = postPhone(code, getAccessToken());
        int errcode = json.getInt("errcode", 0);
        if (errcode == ERR_TOKEN_INVALID) {
            // 凭证被其他实例刷新，清缓存重试一次
            clearAccessToken();
            json = postPhone(code, getAccessToken());
            errcode = json.getInt("errcode", 0);
        }
        if (errcode != 0) {
            log.warn("获取手机号失败, errcode={}, errmsg={}", errcode, json.getStr("errmsg"));
            throw new BusinessException("获取手机号失败，请重试");
        }

        JSONObject phoneInfo = json.getJSONObject("phone_info");
        if (phoneInfo == null) {
            throw new BusinessException("获取手机号失败，请重试");
        }
        String phone = phoneInfo.getStr("purePhoneNumber");
        if (StrUtil.isBlank(phone)) {
            throw new BusinessException("获取手机号失败，请重试");
        }
        return phone;
    }

    /**
     * 文本内容安全检测（官方 msgSecCheck 2.0，同步）
     * <p>
     * 用于检测用户提交的文本是否含违法违规内容。必须在服务端调用。
     *
     * @param openid   用户 openid（该用户需近两小时访问过小程序）
     * @param scene    场景：1 资料；2 评论；3 论坛；4 社交日志
     * @param content  待检测文本，官方上限 2500 字
     * @param nickname 用户昵称，可为空；带上能提升判定准确率
     * @param title    文本标题，可为空
     * @return suggest：pass 通过 / review 疑似 / risky 违规
     */
    public String msgSecCheck(String openid, int scene, String content, String nickname, String title) {
        if (StrUtil.isBlank(content)) {
            return SUGGEST_PASS;
        }
        // 官方硬限制 2500 字：超长只检测前 2500 字，不能因为超长把整条提交打回
        String text = content.length() > MSG_SEC_CHECK_MAX_LENGTH
                ? content.substring(0, MSG_SEC_CHECK_MAX_LENGTH) : content;

        if (wxProperties.isMock()) {
            log.warn("【mock】msgSecCheck 未真实调用, scene={}, length={}", scene, text.length());
            return SUGGEST_PASS;
        }

        JSONObject body = JSONUtil.createObj()
                .set("content", text)
                .set("version", SEC_CHECK_VERSION)
                .set("scene", scene)
                .set("openid", openid);
        if (StrUtil.isNotBlank(nickname)) {
            body.set("nickname", nickname);
        }
        if (StrUtil.isNotBlank(title)) {
            body.set("title", title);
        }

        JSONObject json = postJsonWithRetry(URL_MSG_SEC_CHECK, body.toString(), "msgSecCheck");
        int errcode = json.getInt("errcode", 0);
        if (errcode != 0) {
            log.warn("文本内容检测调用失败, errcode={}, errmsg={}", errcode, json.getStr("errmsg"));
            throw new BusinessException("内容检测服务暂不可用");
        }
        JSONObject result = json.getJSONObject("result");
        return result == null ? SUGGEST_PASS : result.getStr("suggest", SUGGEST_PASS);
    }

    /**
     * 图片内容安全检测（官方 mediaCheckAsync 2.0，异步）
     * <p>
     * 只负责把图片 URL 交给微信并拿回 trace_id；检测结论在 30 分钟内
     * 通过消息推送（Event=wxa_media_check）回传，由推送入口更新状态。
     *
     * @param openid   用户 openid
     * @param scene    场景，口径同文本
     * @param mediaUrl 图片的公网地址，必须能被微信服务器下载
     * @return trace_id，用于匹配异步推送结果
     */
    public String mediaCheckAsync(String openid, int scene, String mediaUrl) {
        if (StrUtil.isBlank(mediaUrl)) {
            return null;
        }
        if (wxProperties.isMock()) {
            String traceId = "mock_" + SecureUtil.md5(mediaUrl);
            log.warn("【mock】mediaCheckAsync 未真实调用, traceId={}, url={}", traceId, mediaUrl);
            return traceId;
        }

        JSONObject body = JSONUtil.createObj()
                .set("media_url", mediaUrl)
                .set("media_type", 2)
                .set("version", SEC_CHECK_VERSION)
                .set("scene", scene)
                .set("openid", openid);

        JSONObject json = postJsonWithRetry(URL_MEDIA_CHECK_ASYNC, body.toString(), "mediaCheckAsync");
        int errcode = json.getInt("errcode", 0);
        if (errcode != 0) {
            log.warn("图片内容检测调用失败, errcode={}, errmsg={}, url={}", errcode, json.getStr("errmsg"), mediaUrl);
            throw new BusinessException("图片检测服务暂不可用");
        }
        return json.getStr("trace_id");
    }

    /**
     * 带 access_token 的 POST，凭证失效时清缓存重试一次
     */
    private JSONObject postJsonWithRetry(String url, String body, String api) {
        JSONObject json = doPostJson(url, body, api, getAccessToken());
        if (json.getInt("errcode", 0) == ERR_TOKEN_INVALID) {
            clearAccessToken();
            json = doPostJson(url, body, api, getAccessToken());
        }
        return json;
    }

    private JSONObject doPostJson(String url, String body, String api, String accessToken) {
        String resp = HttpRequest.post(url + "?access_token=" + accessToken)
                .body(body)
                .timeout(wxProperties.getTimeout())
                .execute()
                .body();
        return parse(resp, api);
    }

    private JSONObject postPhone(String code, String accessToken) {
        String body = JSONUtil.createObj().set("code", code).toString();
        String resp = HttpRequest.post(URL_PHONE + "?access_token=" + accessToken)
                .body(body)
                .timeout(wxProperties.getTimeout())
                .execute()
                .body();
        return parse(resp, "getPhoneNumber");
    }

    private JSONObject parse(String body, String api) {
        if (StrUtil.isBlank(body)) {
            throw new BusinessException("微信接口无响应：" + api);
        }
        try {
            return JSONUtil.parseObj(body);
        } catch (Exception e) {
            log.error("微信接口返回解析失败, api={}, body={}", api, body, e);
            throw new BusinessException("微信接口返回异常");
        }
    }
}
