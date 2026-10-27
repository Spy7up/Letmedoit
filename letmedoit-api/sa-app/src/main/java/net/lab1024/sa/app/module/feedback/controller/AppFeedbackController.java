package net.lab1024.sa.app.module.feedback.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.app.module.feedback.domain.form.AppFeedbackAddForm;
import net.lab1024.sa.app.module.feedback.domain.vo.AppFeedbackTypeVO;
import net.lab1024.sa.app.module.feedback.service.AppFeedbackService;
import net.lab1024.sa.app.util.AppRequestUtil;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 小程序 - 问题与反馈
 * <p>
 * 登录态由 AppInterceptor 统一校验；反馈必须带身份，否则后台没法回溯是谁遇到的问题。
 * <p>
 * ⚠️ 类名一律带 App 前缀：sa-base 的 support 里已经有一个「意见反馈」模块，
 * 同样叫 FeedbackController / FeedbackService。两个应用都在扫 net.lab1024.sa 包，
 * 重名会在启动时报 ConflictingBeanDefinitionException（启动直接失败，不是运行时问题）。
 *
 * @author letmedoit
 */
@RestController
@RequestMapping("/api/feedback")
@Tag(name = "小程序-问题反馈")
public class AppFeedbackController {

    @Resource
    private AppFeedbackService appFeedbackService;

    @GetMapping("/type/list")
    @Operation(summary = "反馈类型列表 @author letmedoit")
    public ResponseDTO<List<AppFeedbackTypeVO>> typeList() {
        return ResponseDTO.ok(appFeedbackService.typeList());
    }

    @PostMapping("/add")
    @Operation(summary = "提交问题与反馈 @author letmedoit")
    public ResponseDTO<Long> add(@RequestBody @Valid AppFeedbackAddForm form) {
        return appFeedbackService.add(form, AppRequestUtil.getMemberId());
    }
}
