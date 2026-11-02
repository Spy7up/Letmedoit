package net.letmedoit.sa.app.module.notice.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.letmedoit.sa.app.module.notice.domain.form.NoticeQueryForm;
import net.letmedoit.sa.app.module.notice.domain.form.NoticeReadForm;
import net.letmedoit.sa.app.module.notice.domain.vo.NoticePageVO;
import net.letmedoit.sa.app.module.notice.service.NoticeService;
import net.letmedoit.sa.app.util.AppRequestUtil;
import net.letmedoit.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 小程序 - 服务通知
 *
 * @author letmedoit
 */
@RestController
@RequestMapping("/api/notice")
@Tag(name = "小程序-服务通知")
public class NoticeController {

    @Resource
    private NoticeService noticeService;

    @PostMapping("/query")
    @Operation(summary = "我的通知（含未读数）")
    public ResponseDTO<NoticePageVO> query(@RequestBody @Valid NoticeQueryForm queryForm) {
        return noticeService.query(queryForm, AppRequestUtil.getMemberId());
    }

    @GetMapping("/unread-count")
    @Operation(summary = "未读数")
    public ResponseDTO<Integer> unreadCount() {
        return noticeService.unreadCount(AppRequestUtil.getMemberId());
    }

    @PostMapping("/read")
    @Operation(summary = "标记已读")
    public ResponseDTO<Integer> read(@RequestBody @Valid NoticeReadForm form) {
        return noticeService.read(form, AppRequestUtil.getMemberId());
    }
}
