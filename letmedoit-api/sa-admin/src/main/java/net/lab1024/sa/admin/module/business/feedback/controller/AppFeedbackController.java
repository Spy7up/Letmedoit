package net.lab1024.sa.admin.module.business.feedback.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.constant.AdminSwaggerTagConst;
import net.lab1024.sa.admin.module.business.feedback.domain.form.AppFeedbackQueryForm;
import net.lab1024.sa.admin.module.business.feedback.domain.form.AppFeedbackReplyForm;
import net.lab1024.sa.admin.module.business.feedback.domain.vo.AppFeedbackVO;
import net.lab1024.sa.admin.module.business.feedback.service.AppFeedbackService;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 小程序反馈（t_app_feedback）
 *
 * @Author 1024创新实验室
 */
@RestController
@Tag(name = AdminSwaggerTagConst.Business.LETMEDOIT_FEEDBACK)
public class AppFeedbackController {

    @Resource
    private AppFeedbackService appFeedbackService;

    @Operation(summary = "反馈分页查询")
    @PostMapping("/appFeedback/query")
    @SaCheckPermission("appFeedback:query")
    public ResponseDTO<PageResult<AppFeedbackVO>> query(@RequestBody @Valid AppFeedbackQueryForm queryForm) {
        return appFeedbackService.query(queryForm);
    }

    @Operation(summary = "反馈详情")
    @GetMapping("/appFeedback/detail/{feedbackId}")
    @SaCheckPermission("appFeedback:query")
    public ResponseDTO<AppFeedbackVO> detail(@PathVariable Long feedbackId) {
        return appFeedbackService.detail(feedbackId);
    }

    @Operation(summary = "回复并流转状态")
    @PostMapping("/appFeedback/reply")
    @SaCheckPermission("appFeedback:reply")
    public ResponseDTO<String> reply(@RequestBody @Valid AppFeedbackReplyForm replyForm) {
        return appFeedbackService.reply(replyForm);
    }
}
