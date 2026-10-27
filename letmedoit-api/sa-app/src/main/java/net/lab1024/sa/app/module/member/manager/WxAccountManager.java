package net.lab1024.sa.app.module.member.manager;

import jakarta.annotation.Resource;
import net.lab1024.sa.app.module.helper.constant.HelperRequestStatusEnum;
import net.lab1024.sa.app.module.helper.dao.HelperDao;
import net.lab1024.sa.app.module.helper.dao.HelperRequestDao;
import net.lab1024.sa.app.module.member.dao.WxMemberDao;
import net.lab1024.sa.base.common.exception.BusinessException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 账号注销（事务层）
 * <p>
 * 做三件事，缺一件都会留下「看不见但还在」的个人信息：
 * <ol>
 *     <li>会员行匿名化 + 逻辑删除：昵称、头像、手机号、邀请码全部清掉，open_id 换掉</li>
 *     <li>清空帮手关系（双向）和待处理申请 —— 别人列表里不该再出现一个不存在的人</li>
 *     <li>任务 / 通知 / 协议同意记录保留：这些是别人的数据和举证材料，
 *         页面上通过 member 表查到的是「已注销用户」，不再含个人信息</li>
 * </ol>
 *
 * @author letmedoit
 */
@Component
public class WxAccountManager {

    /**
     * 注销后的展示名：任务详情、帮手列表里都会显示成这个
     */
    private static final String ANONYMOUS_NICKNAME = "已注销用户";

    @Resource
    private WxMemberDao wxMemberDao;

    @Resource
    private HelperDao helperDao;

    @Resource
    private HelperRequestDao helperRequestDao;

    /**
     * 注销账号
     *
     * @param memberId 会员ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long memberId) {
        LocalDateTime now = LocalDateTime.now();
        // open_id 有唯一索引，必须让位：del_{memberId}_{时间戳}
        String anonymousOpenId = "del_" + memberId + "_" + System.currentTimeMillis();
        int rows = wxMemberDao.anonymizeAndDelete(memberId, anonymousOpenId, ANONYMOUS_NICKNAME, now);
        if (rows == 0) {
            throw new BusinessException("账号状态已变化，请重新登录后再试");
        }
        helperDao.logicDeleteAllByMember(memberId, now);
        helperRequestDao.logicDeletePendingByMember(memberId, HelperRequestStatusEnum.PENDING.getValue(), now);
    }
}
