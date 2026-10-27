package net.lab1024.sa.app.module.helper.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.app.module.helper.domain.form.HelperInviteAcceptForm;
import net.lab1024.sa.app.module.helper.domain.form.HelperRemoveForm;
import net.lab1024.sa.app.module.helper.domain.form.HelperRequestAddForm;
import net.lab1024.sa.app.module.helper.domain.form.HelperRequestHandleForm;
import net.lab1024.sa.app.module.helper.domain.vo.HelperInvitePreviewVO;
import net.lab1024.sa.app.module.helper.domain.vo.HelperInviteVO;
import net.lab1024.sa.app.module.helper.domain.vo.HelperRequestVO;
import net.lab1024.sa.app.module.helper.domain.vo.HelperVO;
import net.lab1024.sa.app.module.helper.service.HelperService;
import net.lab1024.sa.app.util.AppRequestUtil;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 小程序 - 帮手
 *
 * @author letmedoit
 */
@RestController
@RequestMapping("/api/helper")
@Tag(name = "小程序-帮手")
public class HelperController {

    @Resource
    private HelperService helperService;

    @GetMapping("/list")
    @Operation(summary = "帮手列表 @author letmedoit")
    public ResponseDTO<List<HelperVO>> list(@RequestParam(required = false) String keyword) {
        return helperService.list(keyword, AppRequestUtil.getMemberId());
    }

    @GetMapping("/request/list")
    @Operation(summary = "待处理的帮手申请 @author letmedoit")
    public ResponseDTO<List<HelperRequestVO>> requestList() {
        return helperService.requestList(AppRequestUtil.getMemberId());
    }

    @PostMapping("/request/add")
    @Operation(summary = "发起帮手申请 @author letmedoit")
    public ResponseDTO<String> apply(@RequestBody @Valid HelperRequestAddForm form) {
        return helperService.apply(form, AppRequestUtil.getMemberId());
    }

    @PostMapping("/request/accept")
    @Operation(summary = "同意帮手申请 @author letmedoit")
    public ResponseDTO<String> acceptRequest(@RequestBody @Valid HelperRequestHandleForm form) {
        return helperService.acceptRequest(form.getRequestId(), AppRequestUtil.getMemberId());
    }

    @PostMapping("/request/reject")
    @Operation(summary = "拒绝帮手申请 @author letmedoit")
    public ResponseDTO<String> rejectRequest(@RequestBody @Valid HelperRequestHandleForm form) {
        return helperService.rejectRequest(form.getRequestId(), AppRequestUtil.getMemberId());
    }

    @GetMapping("/invite")
    @Operation(summary = "我的邀请码 @author letmedoit")
    public ResponseDTO<HelperInviteVO> invite() {
        return helperService.invite(AppRequestUtil.getMemberId());
    }

    @GetMapping("/invite/{inviteCode}")
    @Operation(summary = "邀请码预览（点开分享卡片的人看） @author letmedoit")
    public ResponseDTO<HelperInvitePreviewVO> invitePreview(@PathVariable String inviteCode) {
        return helperService.invitePreview(inviteCode, AppRequestUtil.getMemberId());
    }

    @PostMapping("/invite/accept")
    @Operation(summary = "输入邀请码加帮手 @author letmedoit")
    public ResponseDTO<String> acceptInvite(@RequestBody @Valid HelperInviteAcceptForm form) {
        return helperService.acceptInvite(form, AppRequestUtil.getMemberId());
    }

    @PostMapping("/remove")
    @Operation(summary = "解除帮手 @author letmedoit")
    public ResponseDTO<String> remove(@RequestBody @Valid HelperRemoveForm form) {
        return helperService.remove(form, AppRequestUtil.getMemberId());
    }
}
