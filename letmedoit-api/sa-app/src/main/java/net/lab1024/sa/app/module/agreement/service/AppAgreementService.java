package net.lab1024.sa.app.module.agreement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.module.agreement.constant.AgreementTypeEnum;
import net.lab1024.sa.app.module.agreement.dao.AppAgreementDao;
import net.lab1024.sa.app.module.agreement.dao.AppAgreementRecordDao;
import net.lab1024.sa.app.module.agreement.domain.entity.AppAgreementEntity;
import net.lab1024.sa.app.module.agreement.domain.entity.AppAgreementRecordEntity;
import net.lab1024.sa.app.module.agreement.domain.vo.AgreementBundleVO;
import net.lab1024.sa.app.module.agreement.domain.vo.AgreementVO;
import net.lab1024.sa.base.common.exception.BusinessException;
import net.lab1024.sa.base.common.util.SmartBeanUtil;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 用户协议 / 隐私政策
 * <p>
 * 三件事：
 * <ol>
 *     <li>给登录页提供当前生效版本（登录时必须同意，不同意不给登）</li>
 *     <li>给协议阅读页提供全文，内容从数据库取，运营者在后台改了立刻生效，不用发版</li>
 *     <li>同意动作落 t_app_agreement_record 留痕（时间 + 版本 + IP + UA）</li>
 * </ol>
 *
 * @author letmedoit
 */
@Slf4j
@Service
public class AppAgreementService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    /**
     * 组合版本分隔符，格式：u{用户协议版本}|p{隐私政策版本}
     */
    private static final String VERSION_SEPARATOR = "|";

    @Resource
    private AppAgreementDao appAgreementDao;

    @Resource
    private AppAgreementRecordDao appAgreementRecordDao;

    /**
     * 当前生效的协议摘要（登录页用，不含正文）
     */
    public AgreementBundleVO current() {
        AppAgreementEntity user = queryActive(AgreementTypeEnum.USER);
        AppAgreementEntity privacy = queryActive(AgreementTypeEnum.PRIVACY);
        if (user == null || privacy == null) {
            // 没配协议就等于没法让用户同意，必须拦下来，不能静默放行
            log.error("协议未配置：用户协议={}, 隐私政策={}，请先执行 docs/sql/init/letmedoit_init.sql",
                    user == null ? "缺失" : "正常", privacy == null ? "缺失" : "正常");
            throw new BusinessException("服务协议尚未配置，请稍后重试");
        }

        AgreementBundleVO vo = new AgreementBundleVO();
        vo.setUserAgreement(summary(user));
        vo.setPrivacyPolicy(summary(privacy));
        vo.setVersion(buildVersion(user, privacy));
        return vo;
    }

    /**
     * 协议全文（阅读页用）
     *
     * @param type user / privacy
     */
    public AgreementVO detail(String type) {
        AgreementTypeEnum typeEnum = AgreementTypeEnum.getByValue(type);
        if (typeEnum == null) {
            throw new BusinessException("协议类型不正确");
        }
        AppAgreementEntity entity = queryActive(typeEnum);
        if (entity == null) {
            throw new BusinessException("协议内容不存在");
        }
        return SmartBeanUtil.copy(entity, AgreementVO.class);
    }

    /**
     * 当前必须同意的组合版本号
     */
    public String requiredVersion() {
        return current().getVersion();
    }

    /**
     * 记录用户同意
     * <p>
     * 登录成功后由后端内部调用，前端无法跳过。传入的组合版本必须与当前生效版本一致，
     * 否则说明用户看的是旧版协议，要求重新阅读。
     *
     * @param memberId      会员
     * @param bundleVersion 前端回传的组合版本
     * @param ip            客户端 IP
     * @param userAgent     客户端标识
     */
    public void agree(Long memberId, String bundleVersion, String ip, String userAgent) {
        String required = requiredVersion();
        if (!StringUtils.hasText(bundleVersion) || !required.equals(bundleVersion)) {
            throw new BusinessException("协议已更新，请重新阅读并同意");
        }
        LocalDateTime now = LocalDateTime.now();
        for (AgreementTypeEnum type : AgreementTypeEnum.values()) {
            AppAgreementEntity doc = queryActive(type);
            if (doc == null) {
                continue;
            }
            Long exists = appAgreementRecordDao.selectCount(new LambdaQueryWrapper<AppAgreementRecordEntity>()
                    .eq(AppAgreementRecordEntity::getMemberId, memberId)
                    .eq(AppAgreementRecordEntity::getAgreementType, type.getValue())
                    .eq(AppAgreementRecordEntity::getVersion, doc.getVersion()));
            if (exists != null && exists > 0) {
                continue;
            }
            AppAgreementRecordEntity record = new AppAgreementRecordEntity();
            record.setMemberId(memberId);
            record.setAgreementType(type.getValue());
            record.setVersion(doc.getVersion());
            record.setAgreeTime(now);
            record.setIp(truncate(ip, 64));
            record.setUserAgent(truncate(userAgent, 255));
            record.setCreateTime(now);
            appAgreementRecordDao.insert(record);
        }
        log.info("用户同意协议, memberId={}, version={}", memberId, bundleVersion);
    }

    /**
     * 是否已经同意过当前版本（供需要判断的地方使用）
     */
    public boolean hasAgreed(Long memberId, AgreementTypeEnum type) {
        AppAgreementEntity doc = queryActive(type);
        if (doc == null) {
            return false;
        }
        Long count = appAgreementRecordDao.selectCount(new LambdaQueryWrapper<AppAgreementRecordEntity>()
                .eq(AppAgreementRecordEntity::getMemberId, memberId)
                .eq(AppAgreementRecordEntity::getAgreementType, type.getValue())
                .eq(AppAgreementRecordEntity::getVersion, doc.getVersion()));
        return count != null && count > 0;
    }

    /**
     * 启动自检：协议没配的话所有登录都会失败，必须让它响一声
     */
    @EventListener(ApplicationReadyEvent.class)
    public void checkRegistered() {
        boolean userOk = queryActive(AgreementTypeEnum.USER) != null;
        boolean privacyOk = queryActive(AgreementTypeEnum.PRIVACY) != null;
        if (userOk && privacyOk) {
            log.info("协议配置正常, 当前版本={}", requiredVersion());
            return;
        }
        log.error("【用户协议】未配置完整（用户协议={}, 隐私政策={}），登录会被拒绝！"
                        + "请执行 docs/sql/init/letmedoit_init.sql",
                userOk ? "正常" : "缺失", privacyOk ? "正常" : "缺失");
    }

    /* ---------------- 内部 ---------------- */

    /**
     * 取某类型当前生效的最新一版
     */
    private AppAgreementEntity queryActive(AgreementTypeEnum type) {
        return appAgreementDao.selectOne(new LambdaQueryWrapper<AppAgreementEntity>()
                .eq(AppAgreementEntity::getType, type.getValue())
                .eq(AppAgreementEntity::getEnabledFlag, Boolean.TRUE)
                .le(AppAgreementEntity::getEffectiveTime, LocalDateTime.now())
                .orderByDesc(AppAgreementEntity::getEffectiveTime)
                .orderByDesc(AppAgreementEntity::getAgreementId)
                .last("LIMIT 1"));
    }

    private AgreementBundleVO.AgreementSummary summary(AppAgreementEntity entity) {
        AgreementBundleVO.AgreementSummary item = new AgreementBundleVO.AgreementSummary();
        item.setType(entity.getType());
        item.setTitle(entity.getTitle());
        item.setVersion(entity.getVersion());
        item.setEffectiveDate(entity.getEffectiveTime() == null
                ? null : entity.getEffectiveTime().format(DATE_FORMATTER));
        return item;
    }

    private String buildVersion(AppAgreementEntity user, AppAgreementEntity privacy) {
        return "u" + user.getVersion() + VERSION_SEPARATOR + "p" + privacy.getVersion();
    }

    private String truncate(String text, int max) {
        if (text == null) {
            return null;
        }
        return text.length() <= max ? text : text.substring(0, max);
    }
}
