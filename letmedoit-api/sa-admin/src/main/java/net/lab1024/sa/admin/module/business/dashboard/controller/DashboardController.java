package net.lab1024.sa.admin.module.business.dashboard.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.constant.AdminSwaggerTagConst;
import net.lab1024.sa.admin.module.business.dashboard.domain.form.DashboardTrendQueryForm;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardOverviewVO;
import net.lab1024.sa.admin.module.business.dashboard.domain.vo.DashboardTrendVO;
import net.lab1024.sa.admin.module.business.dashboard.service.DashboardService;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Tag(name = AdminSwaggerTagConst.Business.LETMEDOIT_DASHBOARD)
public class DashboardController {

    @Resource
    private DashboardService dashboardService;

    @Operation(summary = "运营总览")
    @GetMapping("/dashboard/overview")
    @SaCheckPermission("dashboard:query")
    public ResponseDTO<DashboardOverviewVO> overview() {
        return dashboardService.overview();
    }

    @Operation(summary = "运营趋势")
    @PostMapping("/dashboard/trend")
    @SaCheckPermission("dashboard:query")
    public ResponseDTO<DashboardTrendVO> trend(@RequestBody @Valid DashboardTrendQueryForm queryForm) {
        return dashboardService.trend(queryForm);
    }
}
