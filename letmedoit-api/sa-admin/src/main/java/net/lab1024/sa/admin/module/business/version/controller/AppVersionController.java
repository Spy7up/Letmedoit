package net.lab1024.sa.admin.module.business.version.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.constant.AdminSwaggerTagConst;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionAddForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionPublishForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionQueryForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionUpdateForm;
import net.lab1024.sa.admin.module.business.version.domain.vo.AppVersionVO;
import net.lab1024.sa.admin.module.business.version.service.AppVersionService;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 小程序版本管理
 *
 * @author letmedoit
 */
@RestController
@Tag(name = AdminSwaggerTagConst.Business.LETMEDOIT_VERSION)
public class AppVersionController {

    @Resource
    private AppVersionService appVersionService;

    @Operation(summary = "版本分页查询")
    @PostMapping("/appVersion/query")
    @SaCheckPermission("appVersion:query")
    public ResponseDTO<PageResult<AppVersionVO>> query(@RequestBody @Valid AppVersionQueryForm queryForm) {
        return appVersionService.query(queryForm);
    }

    @Operation(summary = "新增版本")
    @PostMapping("/appVersion/add")
    @SaCheckPermission("appVersion:add")
    public ResponseDTO<String> add(@RequestBody @Valid AppVersionAddForm addForm) {
        return appVersionService.add(addForm);
    }

    @Operation(summary = "修改版本")
    @PostMapping("/appVersion/update")
    @SaCheckPermission("appVersion:update")
    public ResponseDTO<String> update(@RequestBody @Valid AppVersionUpdateForm updateForm) {
        return appVersionService.update(updateForm);
    }

    @Operation(summary = "发布为当前版本")
    @PostMapping("/appVersion/publish")
    @SaCheckPermission("appVersion:publish")
    public ResponseDTO<String> publish(@RequestBody @Valid AppVersionPublishForm publishForm) {
        return appVersionService.publish(publishForm);
    }
}
