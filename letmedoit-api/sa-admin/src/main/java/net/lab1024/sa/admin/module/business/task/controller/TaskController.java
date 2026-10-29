package net.lab1024.sa.admin.module.business.task.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.constant.AdminSwaggerTagConst;
import net.lab1024.sa.admin.module.business.task.domain.form.TaskQueryForm;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskDetailVO;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskVO;
import net.lab1024.sa.admin.module.business.task.service.TaskService;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 任务报表
 *
 * @Author 1024创新实验室
 */
@RestController
@Tag(name = AdminSwaggerTagConst.Business.LETMEDOIT_TASK)
public class TaskController {

    @Resource
    private TaskService taskService;

    @Operation(summary = "任务分页查询")
    @PostMapping("/task/query")
    @SaCheckPermission("task:query")
    public ResponseDTO<PageResult<TaskVO>> query(@RequestBody @Valid TaskQueryForm queryForm) {
        return taskService.query(queryForm);
    }

    @Operation(summary = "任务详情")
    @GetMapping("/task/detail/{taskId}")
    @SaCheckPermission("task:query")
    public ResponseDTO<TaskDetailVO> detail(@PathVariable Long taskId) {
        return taskService.detail(taskId);
    }
}
