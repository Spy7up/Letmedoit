package net.lab1024.sa.admin.module.business.helper.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.constant.AdminSwaggerTagConst;
import net.lab1024.sa.admin.module.business.helper.domain.form.HelperQueryForm;
import net.lab1024.sa.admin.module.business.helper.domain.vo.HelperVO;
import net.lab1024.sa.admin.module.business.helper.service.HelperService;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 帮手关系
 *
 * @Author 1024创新实验室
 */
@RestController
@Tag(name = AdminSwaggerTagConst.Business.LETMEDOIT_HELPER)
public class HelperController {

    @Resource
    private HelperService helperService;

    @Operation(summary = "帮手关系分页查询")
    @PostMapping("/helper/query")
    @SaCheckPermission("helper:query")
    public ResponseDTO<PageResult<HelperVO>> query(@RequestBody @Valid HelperQueryForm queryForm) {
        return helperService.query(queryForm);
    }
}
