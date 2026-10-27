package net.lab1024.sa.app.module.helper.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.module.helper.constant.HelperRequestStatusEnum;
import net.lab1024.sa.app.module.helper.dao.HelperDao;
import net.lab1024.sa.app.module.helper.dao.HelperRequestDao;
import net.lab1024.sa.app.module.helper.domain.entity.HelperEntity;
import net.lab1024.sa.app.module.helper.domain.entity.HelperRequestEntity;
import net.lab1024.sa.app.module.helper.domain.form.HelperInviteAcceptForm;
import net.lab1024.sa.app.module.helper.domain.form.HelperRemoveForm;
import net.lab1024.sa.app.module.helper.domain.form.HelperRequestAddForm;
import net.lab1024.sa.app.module.helper.domain.vo.HelperInvitePreviewVO;
import net.lab1024.sa.app.module.helper.domain.vo.HelperInviteVO;
import net.lab1024.sa.app.module.helper.domain.vo.HelperRequestVO;
import net.lab1024.sa.app.module.helper.domain.vo.HelperVO;
import net.lab1024.sa.app.module.helper.manager.HelperManager;
import net.lab1024.sa.app.module.member.domain.entity.WxMemberEntity;
import net.lab1024.sa.app.module.member.service.WxMemberService;
import net.lab1024.sa.app.module.security.service.ContentSecurityService;
import net.lab1024.sa.app.module.task.manager.TaskManager;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

/**
 * 帮手业务
 *
 * @author letmedoit
 */
@Slf4j
@Service
public class HelperService {

    /**
     * 分享路径，小程序端拼分享卡片用
     */
    private static final String INVITE_SHARE_PATH = "/pages/launch/index?invite=";

    @Resource
    private HelperDao helperDao;

    @Resource
    private ContentSecurityService contentSecurityService;

    @Resource
    private HelperRequestDao helperRequestDao;

    @Resource
    private HelperManager helperManager;

    @Resource
    private WxMemberService wxMemberService;

    /**
     * 我的帮手列表
     */
    public ResponseDTO<List<HelperVO>> list(String keyword, Long memberId) {
        List<HelperVO> list = helperDao.queryList(memberId,
                StringUtils.hasText(keyword) ? keyword.trim() : null,
                Boolean.FALSE, TaskManager.ACTIVE_TASK_STATUS);
        list.forEach(item -> item.setDisplayName(
                StringUtils.hasText(item.getRemark()) ? item.getRemark() : item.getNickname()));
        return ResponseDTO.ok(list);
    }

    /**
     * 我收到的待处理申请
     */
    public ResponseDTO<List<HelperRequestVO>> requestList(Long memberId) {
        List<HelperRequestVO> list = helperRequestDao.queryByToMember(memberId,
                HelperRequestStatusEnum.PENDING.getValue(), Boolean.FALSE);
        return ResponseDTO.ok(list);
    }

    /**
     * 发起帮手申请
     */
    public ResponseDTO<String> apply(HelperRequestAddForm form, Long memberId) {
        if (Objects.equals(form.getToMemberId(), memberId)) {
            return ResponseDTO.userErrorParam("不能加自己为帮手");
        }
        // 内容安全：申请附言对方能直接看到
        contentSecurityService.checkText("申请附言", form.getApplyMessage());
        WxMemberEntity target = wxMemberService.getById(form.getToMemberId());
        if (target == null || Boolean.TRUE.equals(target.getDeletedFlag())) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST, "对方不存在");
        }
        HelperEntity relation = helperDao.queryByMemberAndHelper(memberId, form.getToMemberId(), Boolean.FALSE);
        if (relation != null) {
            return ResponseDTO.userErrorParam("你们已经是彼此的帮手了");
        }
        HelperRequestEntity pending = helperRequestDao.queryPending(memberId, form.getToMemberId(),
                HelperRequestStatusEnum.PENDING.getValue(), Boolean.FALSE);
        if (pending != null) {
            return ResponseDTO.userErrorParam("请求已发出，等 TA 确认");
        }

        LocalDateTime now = LocalDateTime.now();
        HelperRequestEntity entity = new HelperRequestEntity();
        entity.setFromMemberId(memberId);
        entity.setToMemberId(form.getToMemberId());
        entity.setApplyMessage(StringUtils.hasText(form.getApplyMessage()) ? form.getApplyMessage().trim() : null);
        entity.setStatus(HelperRequestStatusEnum.PENDING.getValue());
        entity.setDeletedFlag(Boolean.FALSE);
        entity.setCreateTime(now);
        entity.setUpdateTime(now);
        helperRequestDao.insert(entity);
        return ResponseDTO.ok("已发送，等 TA 同意");
    }

    /**
     * 同意申请
     */
    public ResponseDTO<String> acceptRequest(Long requestId, Long memberId) {
        HelperRequestEntity request = helperRequestDao.queryById(requestId, Boolean.FALSE);
        ResponseDTO<String> check = checkRequestOwner(request, memberId);
        if (check != null) {
            return check;
        }
        helperManager.acceptRequest(request);
        log.info("帮手申请通过, requestId={}, memberId={}", requestId, memberId);
        return ResponseDTO.ok("已加为帮手");
    }

    /**
     * 拒绝申请
     */
    public ResponseDTO<String> rejectRequest(Long requestId, Long memberId) {
        HelperRequestEntity request = helperRequestDao.queryById(requestId, Boolean.FALSE);
        ResponseDTO<String> check = checkRequestOwner(request, memberId);
        if (check != null) {
            return check;
        }
        helperManager.rejectRequest(request);
        return ResponseDTO.ok("已忽略");
    }

    /**
     * 我的邀请码
     */
    public ResponseDTO<HelperInviteVO> invite(Long memberId) {
        WxMemberEntity member = wxMemberService.getById(memberId);
        if (member == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST, "会员不存在");
        }
        if (!StringUtils.hasText(member.getInviteCode())) {
            // 理论上登录时已经初始化；这里兜底再查一次
            return ResponseDTO.userErrorParam("邀请码生成中，请稍后重试");
        }
        HelperInviteVO vo = new HelperInviteVO();
        vo.setInviteCode(member.getInviteCode());
        vo.setSharePath(INVITE_SHARE_PATH + member.getInviteCode());
        return ResponseDTO.ok(vo);
    }

    /**
     * 邀请码预览：分享卡片点进来的人，先看清「谁邀请我」再决定加不加
     * <p>
     * 只返回昵称、头像和两个判定位，不暴露对方的帮手数/任务数。
     */
    public ResponseDTO<HelperInvitePreviewVO> invitePreview(String inviteCode, Long memberId) {
        WxMemberEntity target = wxMemberService.getByInviteCode(inviteCode);
        if (target == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST, "邀请码不存在或已失效");
        }
        HelperInvitePreviewVO vo = new HelperInvitePreviewVO();
        vo.setInviteCode(inviteCode);
        vo.setMemberId(target.getMemberId());
        vo.setNickname(target.getNickname());
        vo.setAvatar(target.getAvatar());
        boolean self = Objects.equals(target.getMemberId(), memberId);
        vo.setSelfFlag(self);
        vo.setHelperFlag(!self
                && helperDao.queryByMemberAndHelper(memberId, target.getMemberId(), Boolean.FALSE) != null);
        return ResponseDTO.ok(vo);
    }

    /**
     * 输入邀请码直接加帮手（不需要对方确认，适合家里长辈面对面）
     */
    public ResponseDTO<String> acceptInvite(HelperInviteAcceptForm form, Long memberId) {
        WxMemberEntity target = wxMemberService.getByInviteCode(form.getInviteCode());
        if (target == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST, "邀请码不存在");
        }
        if (Objects.equals(target.getMemberId(), memberId)) {
            return ResponseDTO.userErrorParam("不能加自己为帮手");
        }
        HelperEntity relation = helperDao.queryByMemberAndHelper(memberId, target.getMemberId(), Boolean.FALSE);
        if (relation != null) {
            return ResponseDTO.userErrorParam("你们已经是彼此的帮手了");
        }
        helperManager.addHelper(memberId, target.getMemberId());
        log.info("邀请码添加帮手, memberId={}, targetId={}", memberId, target.getMemberId());
        return ResponseDTO.ok("已加上 " + (StringUtils.hasText(target.getNickname()) ? target.getNickname() : "帮手"));
    }

    /**
     * 解除帮手
     */
    public ResponseDTO<String> remove(HelperRemoveForm form, Long memberId) {
        HelperEntity relation = helperDao.queryById(form.getHelperId(), Boolean.FALSE);
        if (relation == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST, "帮手关系不存在");
        }
        if (!Objects.equals(relation.getMemberId(), memberId)) {
            return ResponseDTO.error(UserErrorCode.NO_PERMISSION, "只能解除自己的帮手");
        }
        helperManager.removeHelper(memberId, relation.getHelperMemberId());
        return ResponseDTO.ok("已解除");
    }

    private ResponseDTO<String> checkRequestOwner(HelperRequestEntity request, Long memberId) {
        if (request == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST, "申请不存在");
        }
        if (!Objects.equals(request.getToMemberId(), memberId)) {
            return ResponseDTO.error(UserErrorCode.NO_PERMISSION, "这不是发给你的申请");
        }
        if (!HelperRequestStatusEnum.PENDING.getValue().equals(request.getStatus())) {
            return ResponseDTO.userErrorParam("该申请已处理");
        }
        return null;
    }
}
