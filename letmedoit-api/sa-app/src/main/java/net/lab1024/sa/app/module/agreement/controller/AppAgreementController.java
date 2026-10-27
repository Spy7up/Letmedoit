package net.lab1024.sa.app.module.agreement.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import net.lab1024.sa.app.module.agreement.domain.vo.AgreementBundleVO;
import net.lab1024.sa.app.module.agreement.domain.vo.AgreementVO;
import net.lab1024.sa.app.module.agreement.service.AppAgreementService;
import net.lab1024.sa.app.module.member.domain.RequestMember;
import net.lab1024.sa.app.util.AppRequestUtil;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 小程序 - 用户协议与隐私政策
 * <p>
 * current / detail 必须免登录：登录页就要展示协议、点进去要能读，
 * 那时候用户还没 token。白名单在 AppMvcConfig 里配。
 *
 * @author letmedoit
 */
@RestController
@RequestMapping("/api/agreement")
@Tag(name = "小程序-用户协议")
public class AppAgreementController {

    @Resource
    private AppAgreementService appAgreementService;

    @GetMapping("/current")
    @Operation(summary = "当前生效的协议摘要（免登录） @author letmedoit")
    public ResponseDTO<AgreementBundleVO> current() {
        return ResponseDTO.ok(appAgreementService.current());
    }

    @GetMapping("/detail")
    @Operation(summary = "协议全文（免登录） @author letmedoit")
    public ResponseDTO<AgreementVO> detail(@RequestParam String type) {
        return ResponseDTO.ok(appAgreementService.detail(type));
    }

    @PostMapping("/agree")
    @Operation(summary = "同意协议（需登录，用于协议更新后补同意） @author letmedoit")
    public ResponseDTO<String> agree(@RequestParam String version) {
        RequestMember member = AppRequestUtil.getMember();
        if (member == null) {
            return ResponseDTO.error(UserErrorCode.LOGIN_STATE_INVALID);
        }
        appAgreementService.agree(member.getMemberId(), version, member.getIp(), member.getUserAgent());
        return ResponseDTO.ok("已记录");
    }
}
