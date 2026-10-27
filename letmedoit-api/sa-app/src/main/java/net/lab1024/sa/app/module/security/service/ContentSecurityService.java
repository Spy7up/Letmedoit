package net.lab1024.sa.app.module.security.service;

import cn.hutool.json.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.config.WxProperties;
import net.lab1024.sa.app.module.member.domain.RequestMember;
import net.lab1024.sa.app.module.security.constant.ContentBizTypeEnum;
import net.lab1024.sa.app.module.security.constant.ContentCheckStatusEnum;
import net.lab1024.sa.app.module.security.dao.ContentCheckDao;
import net.lab1024.sa.app.module.security.domain.entity.ContentCheckEntity;
import net.lab1024.sa.app.module.wx.WxApiService;
import net.lab1024.sa.app.util.AppRequestUtil;
import net.lab1024.sa.base.common.exception.BusinessException;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 内容安全检测
 * <p>
 * 小程序审核硬性要求：所有用户输入与上传图片都必须过微信内容安全接口。
 * <ul>
 *     <li>文本走 {@code msgSecCheck}（同步），命中即拒绝提交</li>
 *     <li>图片走 {@code mediaCheckAsync}（异步），先放行，违规结果通过消息推送回传后下架</li>
 * </ul>
 * 关闭检测（wx.miniapp.content-check.enabled=false）只用于临时排障，
 * 关着提交审核会被驳回。
 *
 * @author letmedoit
 */
@Slf4j
@Service
public class ContentSecurityService {

    /**
     * 命中风险的统一话术：不告诉用户具体命中哪一类，避免被绕过
     */
    private static final String RISKY_TIP = "含有不适合发布的内容，请修改后再提交";

    /**
     * 文本记录里最多留多少字做排查用
     */
    private static final int BRIEF_LENGTH = 100;

    @Resource
    private WxApiService wxApiService;

    @Resource
    private WxProperties wxProperties;

    @Resource
    private ContentCheckDao contentCheckDao;

    @Resource
    private ContentTakedownService contentTakedownService;

    /* ---------------- 文本 ---------------- */

    /**
     * 文本检测（默认场景），命中风险抛业务异常
     *
     * @param fieldLabel 字段中文名，用在错误提示里，如「任务标题」
     * @param content    待检测文本
     */
    public void checkText(String fieldLabel, String content) {
        checkText(wxProperties.getContentCheck().getTextScene(), fieldLabel, content, null, null);
    }

    /**
     * 文本检测，命中风险抛业务异常
     *
     * @param scene    场景：1 资料 2 评论 3 论坛 4 社交日志
     * @param content  待检测文本
     * @param nickname 用户昵称，可为空
     * @param title    文本标题，可为空
     */
    public void checkText(int scene, String fieldLabel, String content, String nickname, String title) {
        if (!StringUtils.hasText(content) || !wxProperties.isContentCheckActive()) {
            return;
        }
        RequestMember member = AppRequestUtil.getMember();
        doCheckText(member == null ? null : member.getOpenId(), member, scene,
                fieldLabel, content, nickname, title);
    }

    /**
     * 指定 openid 的文本检测
     * <p>
     * 登录流程用：那时还没有 token，AppRequestUtil 里取不到人，
     * 但 code2session 已经拿到 openid 了。
     */
    public void checkTextWithOpenid(String openid, int scene, String fieldLabel, String content) {
        if (!StringUtils.hasText(content) || !wxProperties.isContentCheckActive()) {
            return;
        }
        doCheckText(openid, null, scene, fieldLabel, content, null, null);
    }

    /**
     * 用户资料类文本（昵称等），场景固定用「1 资料」
     * <p>
     * 登录流程 openid 已经拿到、但登录态还没建立，所以显式传进来。
     */
    public void checkProfileText(String openid, String fieldLabel, String content) {
        if (!StringUtils.hasText(content) || !wxProperties.isContentCheckActive()) {
            return;
        }
        RequestMember member = AppRequestUtil.getMember();
        String finalOpenid = StringUtils.hasText(openid)
                ? openid : (member == null ? null : member.getOpenId());
        // 昵称本身也作为 nickname 参数带上，微信侧判定更准
        doCheckText(finalOpenid, member, wxProperties.getContentCheck().getAvatarScene(),
                fieldLabel, content, content, null);
    }

    private void doCheckText(String openid, RequestMember member, int scene,
                             String fieldLabel, String content, String nickname, String title) {
        String suggest;
        try {
            suggest = wxApiService.msgSecCheck(openid, scene, content, nickname, title);
        } catch (Exception e) {
            log.error("文本内容检测调用异常, field={}, memberId={}", fieldLabel,
                    member == null ? null : member.getMemberId(), e);
            // 微信侧抖动时是否放行由配置决定，默认放行（不能因为微信接口挂了让所有人发不出任务）
            if (wxProperties.getContentCheck().isFailOpen()) {
                return;
            }
            throw new BusinessException("内容检测失败，请稍后重试");
        }

        saveTextRecord(member, scene, content, suggest);
        if (!WxApiService.SUGGEST_PASS.equals(suggest)) {
            log.warn("文本命中风险, field={}, suggest={}, memberId={}", fieldLabel, suggest,
                    member == null ? null : member.getMemberId());
            throw new BusinessException(fieldLabel + RISKY_TIP);
        }
    }

    /**
     * 校验图片地址都来自「已经送过检」的上传
     * <p>
     * 图片检测挂在 `/api/file/upload` 上，但如果客户端直接在任务表单里塞一串公网 URL，
     * 就绕过了上传接口、也就绕过了检测。这里按 t_content_check 的记录反查：
     * 查不到记录说明这张图从没送检过，直接拒。
     * <p>
     * mock 模式跳过 —— 本地自检用假 URL，查库必然查不到。
     */
    public void assertImagesTrusted(List<String> urls) {
        if (CollectionUtils.isEmpty(urls) || !wxProperties.isContentCheckActive() || wxProperties.isMock()) {
            return;
        }
        for (String url : urls) {
            if (!StringUtils.hasText(url)) {
                continue;
            }
            Long count = contentCheckDao.selectCount(new LambdaQueryWrapper<ContentCheckEntity>()
                    .eq(ContentCheckEntity::getMediaUrl, url)
                    .in(ContentCheckEntity::getStatus,
                            ContentCheckStatusEnum.PENDING.getValue(),
                            ContentCheckStatusEnum.PASS.getValue(),
                            ContentCheckStatusEnum.FAIL.getValue()));
            if (count == null || count == 0) {
                log.warn("图片未送检就想入库, url={}", url);
                throw new BusinessException("有图片未通过安全检测，请重新上传");
            }
        }
    }

    /* ---------------- 图片 ---------------- */

    /**
     * 批量提交图片异步检测（上传完成后调用，不阻塞业务）
     */
    public void checkImagesAsync(ContentBizTypeEnum bizType, List<String> urls) {
        if (CollectionUtils.isEmpty(urls)) {
            return;
        }
        for (String url : urls) {
            checkImageAsync(bizType, url);
        }
    }

    /**
     * 单张图片异步检测
     * <p>
     * 拿回 trace_id 落库等推送；调用失败时按 failOpen 决定是否拦下这次上传。
     */
    public void checkImageAsync(ContentBizTypeEnum bizType, String url) {
        if (!StringUtils.hasText(url) || !wxProperties.isContentCheckActive()) {
            return;
        }
        WxProperties.ContentCheck cfg = wxProperties.getContentCheck();
        int scene = bizType == ContentBizTypeEnum.AVATAR ? cfg.getAvatarScene() : cfg.getImageScene();
        RequestMember member = AppRequestUtil.getMember();
        String openid = member == null ? null : member.getOpenId();

        String traceId;
        try {
            traceId = wxApiService.mediaCheckAsync(openid, scene, url);
        } catch (Exception e) {
            log.error("图片内容检测调用异常, url={}, bizType={}", url, bizType.getValue(), e);
            saveImageRecord(member, bizType, scene, url, null, ContentCheckStatusEnum.FAIL, null, null, e.getMessage());
            if (cfg.isFailOpen()) {
                return;
            }
            throw new BusinessException("图片检测失败，请重新上传");
        }
        saveImageRecord(member, bizType, scene, url, traceId, ContentCheckStatusEnum.PENDING, null, null, null);
    }

    /* ---------------- 异步结果 ---------------- */

    /**
     * 处理微信推送回来的图片检测结果（Event = wxa_media_check）
     *
     * @param event 推送体
     */
    public void handleMediaCheckEvent(JSONObject event) {
        if (event == null) {
            return;
        }
        String traceId = event.getStr("trace_id");
        if (!StringUtils.hasText(traceId)) {
            log.warn("消息推送缺少 trace_id，忽略");
            return;
        }
        ContentCheckEntity check = contentCheckDao.selectOne(new LambdaQueryWrapper<ContentCheckEntity>()
                .eq(ContentCheckEntity::getTraceId, traceId)
                .last("LIMIT 1"));
        if (check == null) {
            log.warn("收到未知 trace_id 的检测结果, traceId={}", traceId);
            return;
        }

        Integer errcode = event.getInt("errcode");
        if (errcode != null && errcode != 0) {
            // -1008 表示微信下载不到图片，检查 media_url 是否公网可访问
            updateResult(check, ContentCheckStatusEnum.FAIL, null, null, "微信检测失败 errcode=" + errcode);
            return;
        }

        JSONObject result = event.getJSONObject("result");
        String suggest = result == null
                ? WxApiService.SUGGEST_PASS
                : result.getStr("suggest");
        Integer label = result == null ? null : result.getInt("label");
        if (!StringUtils.hasText(suggest)) {
            suggest = WxApiService.SUGGEST_PASS;
        }

        boolean pass = WxApiService.SUGGEST_PASS.equals(suggest);
        updateResult(check, pass ? ContentCheckStatusEnum.PASS : ContentCheckStatusEnum.RISKY, label, suggest, null);
        if (!pass) {
            log.warn("图片命中风险, traceId={}, suggest={}, label={}", traceId, suggest, label);
            contentTakedownService.takeDown(check);
        }
    }

    /**
     * 超时兜底：异步结果 30 分钟内会推送，超过配置时长还没回的直接标记失败
     * <p>
     * 不做下架 —— 图片在提交时已经放行，超时只说明微信没回，不能因此误伤正常用户。
     *
     * @return 处理条数
     */
    public int sweepTimeout() {
        WxProperties.ContentCheck cfg = wxProperties.getContentCheck();
        LocalDateTime deadline = LocalDateTime.now().minusMinutes(cfg.getPendingTimeoutMinutes());
        List<ContentCheckEntity> list = contentCheckDao.selectList(new LambdaQueryWrapper<ContentCheckEntity>()
                .eq(ContentCheckEntity::getStatus, ContentCheckStatusEnum.PENDING.getValue())
                .lt(ContentCheckEntity::getCreateTime, deadline)
                .last("LIMIT 500"));
        for (ContentCheckEntity check : list) {
            updateResult(check, ContentCheckStatusEnum.FAIL, null, null, "超时未收到检测结果");
        }
        if (!list.isEmpty()) {
            log.warn("图片检测超时兜底 {} 条", list.size());
        }
        return list.size();
    }

    /* ---------------- 落库 ---------------- */

    private void saveTextRecord(RequestMember member, int scene, String content, String suggest) {
        ContentCheckEntity entity = new ContentCheckEntity();
        entity.setMemberId(member == null ? null : member.getMemberId());
        entity.setBizType("text");
        entity.setScene(scene);
        entity.setMediaType(0);
        entity.setContentBrief(brief(content));
        entity.setStatus(WxApiService.SUGGEST_PASS.equals(suggest)
                ? ContentCheckStatusEnum.PASS.getValue() : ContentCheckStatusEnum.RISKY.getValue());
        entity.setSuggest(suggest);
        entity.setCreateTime(LocalDateTime.now());
        entity.setUpdateTime(entity.getCreateTime());
        contentCheckDao.insert(entity);
    }

    private void saveImageRecord(RequestMember member, ContentBizTypeEnum bizType, int scene, String url,
                                 String traceId, ContentCheckStatusEnum status, Integer label,
                                 String suggest, String errMsg) {
        ContentCheckEntity entity = new ContentCheckEntity();
        entity.setTraceId(traceId);
        entity.setMemberId(member == null ? null : member.getMemberId());
        entity.setBizType(bizType.getValue());
        entity.setScene(scene);
        entity.setMediaUrl(url);
        entity.setMediaType(2);
        entity.setStatus(status.getValue());
        entity.setLabel(label);
        entity.setSuggest(suggest);
        entity.setErrMsg(truncate(errMsg, 200));
        entity.setCreateTime(LocalDateTime.now());
        entity.setUpdateTime(entity.getCreateTime());
        contentCheckDao.insert(entity);
    }

    private void updateResult(ContentCheckEntity check, ContentCheckStatusEnum status,
                              Integer label, String suggest, String errMsg) {
        ContentCheckEntity update = new ContentCheckEntity();
        update.setCheckId(check.getCheckId());
        update.setStatus(status.getValue());
        update.setLabel(label);
        update.setSuggest(suggest);
        update.setErrMsg(truncate(errMsg, 200));
        update.setUpdateTime(LocalDateTime.now());
        contentCheckDao.updateById(update);
        // 让内存里的对象同步，下架逻辑不必再查一次库
        check.setStatus(status.getValue());
        check.setLabel(label);
        check.setSuggest(suggest);
    }

    private String brief(String content) {
        return truncate(content == null ? null : content.trim(), BRIEF_LENGTH);
    }

    private String truncate(String text, int max) {
        if (text == null) {
            return null;
        }
        return text.length() <= max ? text : text.substring(0, max);
    }
}
