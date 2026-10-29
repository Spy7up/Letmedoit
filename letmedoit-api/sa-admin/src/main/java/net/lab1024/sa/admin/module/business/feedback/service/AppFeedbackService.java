package net.lab1024.sa.admin.module.business.feedback.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.feedback.constant.AppFeedbackStatusEnum;
import net.lab1024.sa.admin.module.business.feedback.dao.AppFeedbackDao;
import net.lab1024.sa.admin.module.business.feedback.domain.form.AppFeedbackQueryForm;
import net.lab1024.sa.admin.module.business.feedback.domain.form.AppFeedbackReplyForm;
import net.lab1024.sa.admin.module.business.feedback.domain.vo.AppFeedbackVO;
import net.lab1024.sa.admin.util.AdminRequestUtil;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 小程序反馈处理
 *
 * @Author 1024创新实验室
 */
@Service
public class AppFeedbackService {

    @Resource
    private AppFeedbackDao appFeedbackDao;

    public ResponseDTO<PageResult<AppFeedbackVO>> query(AppFeedbackQueryForm queryForm) {
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<AppFeedbackVO> list = appFeedbackDao.query(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    public ResponseDTO<AppFeedbackVO> detail(Long feedbackId) {
        AppFeedbackVO vo = appFeedbackDao.selectDetail(feedbackId);
        if (vo == null) {
            return ResponseDTO.userErrorParam("反馈不存在或已删除");
        }
        return ResponseDTO.ok(vo);
    }

    public ResponseDTO<String> reply(AppFeedbackReplyForm replyForm) {
        Integer currentStatus = appFeedbackDao.selectStatus(replyForm.getFeedbackId());
        if (currentStatus == null) {
            return ResponseDTO.userErrorParam("反馈不存在或已删除");
        }
        Integer targetStatus = replyForm.getStatus();
        AppFeedbackStatusEnum targetEnum = AppFeedbackStatusEnum.getByValue(targetStatus);
        if (targetEnum == null) {
            return ResponseDTO.userErrorParam("处理状态不合法");
        }
        if (!AppFeedbackStatusEnum.allowNextStatus(currentStatus).contains(targetStatus)) {
            AppFeedbackStatusEnum currentEnum = AppFeedbackStatusEnum.getByValue(currentStatus);
            String currentDesc = currentEnum == null ? String.valueOf(currentStatus) : currentEnum.getDesc();
            return ResponseDTO.userErrorParam("当前状态为「" + currentDesc + "」，不能流转到「" + targetEnum.getDesc() + "」");
        }
        String replyContent = replyForm.getReplyContent() == null ? null : replyForm.getReplyContent().trim();
        boolean replyBlank = replyContent == null || replyContent.isEmpty();
        if (AppFeedbackStatusEnum.RESOLVED.getValue().equals(targetStatus) && replyBlank) {
            return ResponseDTO.userErrorParam("标记已解决时必须填写回复内容");
        }
        int updateCount = appFeedbackDao.updateReply(replyForm.getFeedbackId(), currentStatus, targetStatus,
                replyBlank ? null : replyContent, AdminRequestUtil.getRequestUserId());
        if (updateCount == 0) {
            return ResponseDTO.userErrorParam("该反馈刚刚被其他人处理，请刷新后重试");
        }
        return ResponseDTO.ok();
    }
}
