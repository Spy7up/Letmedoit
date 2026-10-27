package net.lab1024.sa.app.module.feedback.service;

import com.alibaba.fastjson.JSON;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.module.dict.constant.AppDictCode;
import net.lab1024.sa.app.module.dict.service.AppDictService;
import net.lab1024.sa.app.module.feedback.constant.FeedbackStatusEnum;
import net.lab1024.sa.app.module.feedback.constant.FeedbackTypeEnum;
import net.lab1024.sa.app.module.feedback.dao.AppFeedbackDao;
import net.lab1024.sa.app.module.feedback.domain.entity.AppFeedbackEntity;
import net.lab1024.sa.app.module.feedback.domain.form.AppFeedbackAddForm;
import net.lab1024.sa.app.module.feedback.domain.vo.AppFeedbackTypeVO;
import net.lab1024.sa.app.module.security.service.ContentSecurityService;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 问题与反馈
 * <p>
 * 只做「校验 + 落库」，没有通知、没有积分：反馈是单向通道，
 * 后台处理完如果需要回复用户，走后续的「我的反馈」页（本期不做）。
 *
 * @author letmedoit
 */
@Slf4j
@Service
public class AppFeedbackService {

    /**
     * 一条反馈最多几张图（产品规则：最多三张）
     */
    public static final int MAX_IMAGE_COUNT = 3;

    /**
     * 单条 URL 长度上限，与任务附图保持一致
     */
    private static final int MAX_URL_LENGTH = 500;

    @Resource
    private AppFeedbackDao appFeedbackDao;

    @Resource
    private ContentSecurityService contentSecurityService;

    @Resource
    private AppDictService appDictService;

    /**
     * 反馈类型列表
     * <p>
     * 文案走数据字典 FEEDBACK_TYPE：后台改一个词，小程序不用发版。
     * 字典没初始化时退回枚举 desc，接口永远不返回空列表。
     */
    public List<AppFeedbackTypeVO> typeList() {
        List<AppFeedbackTypeVO> list = new ArrayList<>(FeedbackTypeEnum.values().length);
        for (FeedbackTypeEnum item : FeedbackTypeEnum.values()) {
            list.add(new AppFeedbackTypeVO(item.getValue(),
                    appDictService.label(AppDictCode.FEEDBACK_TYPE, item)));
        }
        return list;
    }

    /**
     * 提交反馈
     *
     * @param form     表单
     * @param memberId 当前会员
     * @return 反馈ID
     */
    public ResponseDTO<Long> add(AppFeedbackAddForm form, Long memberId) {
        if (memberId == null) {
            return ResponseDTO.userErrorParam("登录态失效，请重新进入");
        }
        FeedbackTypeEnum type = FeedbackTypeEnum.getByValue(form.getType());
        if (type == null) {
            return ResponseDTO.userErrorParam("反馈类型不对");
        }
        String content = StringUtils.hasText(form.getContent()) ? form.getContent().trim() : "";
        if (!StringUtils.hasText(content)) {
            return ResponseDTO.userErrorParam("说说遇到的情况吧");
        }

        // 内容安全：反馈内容是 UGC，后台要给人看，同样必须过文本检测
        contentSecurityService.checkText("反馈内容", content);

        // 图片必须来自走过上传检测的地址，直接塞公网 URL 绕不过内容安全
        List<String> images = normalizeImages(form.getImages());
        contentSecurityService.assertImagesTrusted(images);

        AppFeedbackEntity entity = new AppFeedbackEntity();
        entity.setMemberId(memberId);
        entity.setType(type.getValue());
        entity.setContent(content);
        entity.setImages(images.isEmpty() ? null : JSON.toJSONString(images));
        entity.setContact(StringUtils.hasText(form.getContact()) ? form.getContact().trim() : null);
        entity.setStatus(FeedbackStatusEnum.PENDING.getValue());
        entity.setDeletedFlag(Boolean.FALSE);
        LocalDateTime now = LocalDateTime.now();
        entity.setCreateTime(now);
        entity.setUpdateTime(now);
        appFeedbackDao.insert(entity);

        log.info("收到反馈, feedbackId={}, memberId={}, type={}, 图片={}张",
                entity.getFeedbackId(), memberId, type.getValue(), images.size());
        return ResponseDTO.ok(entity.getFeedbackId());
    }

    /**
     * 清洗图片地址
     * <p>
     * 三条规则和任务附图一致：只收公网 http(s)、排掉微信临时路径、最多 3 张。
     * 服务端必须自己判，不能指望客户端拦住。
     */
    private List<String> normalizeImages(List<String> images) {
        Set<String> result = new LinkedHashSet<>();
        if (CollectionUtils.isEmpty(images)) {
            return new ArrayList<>();
        }
        for (String raw : images) {
            if (!StringUtils.hasText(raw)) {
                continue;
            }
            String url = raw.trim();
            if (url.length() > MAX_URL_LENGTH) {
                continue;
            }
            if (!url.startsWith("http://") && !url.startsWith("https://")) {
                continue;
            }
            if (url.startsWith("wxfile://") || url.startsWith("http://tmp") || url.contains("/tmp/")) {
                continue;
            }
            result.add(url);
            if (result.size() >= MAX_IMAGE_COUNT) {
                break;
            }
        }
        return new ArrayList<>(result);
    }
}
