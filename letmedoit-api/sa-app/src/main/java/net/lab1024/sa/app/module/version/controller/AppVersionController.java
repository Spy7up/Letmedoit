package net.lab1024.sa.app.module.version.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import net.lab1024.sa.app.module.version.constant.VersionPlatformEnum;
import net.lab1024.sa.app.module.version.domain.vo.AppVersionVO;
import net.lab1024.sa.app.module.version.service.AppVersionService;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 小程序 - 版本
 * <p>
 * /current 必须免登录：登录页也可能要展示版本，而且版本号不属于用户数据。
 * 白名单在 AppMvcConfig 里配。
 *
 * @author letmedoit
 */
@RestController
@RequestMapping("/api/version")
@Tag(name = "小程序-版本")
public class AppVersionController {

    @Resource
    private AppVersionService appVersionService;

    @GetMapping("/current")
    @Operation(summary = "当前版本（免登录） @author letmedoit")
    public ResponseDTO<AppVersionVO> current() {
        return ResponseDTO.ok(appVersionService.current(VersionPlatformEnum.MINIAPP.getValue()));
    }
}
