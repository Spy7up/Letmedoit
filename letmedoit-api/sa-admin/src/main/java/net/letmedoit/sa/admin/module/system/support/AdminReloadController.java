package net.letmedoit.sa.admin.module.system.support;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.letmedoit.sa.base.common.controller.SupportBaseController;
import net.letmedoit.sa.base.common.domain.ResponseDTO;
import net.letmedoit.sa.base.constant.SwaggerTagConst;
import net.letmedoit.sa.base.module.support.reload.ReloadService;
import net.letmedoit.sa.base.module.support.reload.domain.ReloadForm;
import net.letmedoit.sa.base.module.support.reload.domain.ReloadItemVO;
import net.letmedoit.sa.base.module.support.reload.domain.ReloadResultVO;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * reload (内存热加载、钩子等)
 *
 * @author letmedoit
 */
@RestController
@Tag(name = SwaggerTagConst.Support.RELOAD)
public class AdminReloadController extends SupportBaseController {

    @Resource
    private ReloadService reloadService;

    @Operation(summary = "查询reload列表")
    @GetMapping("/reload/query")
    public ResponseDTO<List<ReloadItemVO>> query() {
        return reloadService.query();
    }

    @Operation(summary = "获取reload result")
    @GetMapping("/reload/result/{tag}")
    @SaCheckPermission("support:reload:result")
    public ResponseDTO<List<ReloadResultVO>> queryReloadResult(@PathVariable("tag") String tag) {
        return reloadService.queryReloadItemResult(tag);
    }

    @Operation(summary = "通过tag更新标识")
    @PostMapping("/reload/update")
    @SaCheckPermission("support:reload:update")
    public ResponseDTO<String> updateByTag(@RequestBody @Valid ReloadForm reloadForm) {
        return reloadService.updateByTag(reloadForm);
    }
}
