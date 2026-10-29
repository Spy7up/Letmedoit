package net.lab1024.sa.admin.module.business.task.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.task.dao.TaskDao;
import net.lab1024.sa.admin.module.business.task.domain.form.TaskQueryForm;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskDetailVO;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskVO;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 任务（只读报表）
 *
 * @Author 1024创新实验室
 */
@Service
public class TaskService {

    @Resource
    private TaskDao taskDao;

    public ResponseDTO<PageResult<TaskVO>> query(TaskQueryForm queryForm) {
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<TaskVO> list = taskDao.query(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    public ResponseDTO<TaskDetailVO> detail(Long taskId) {
        if (taskId == null) {
            return ResponseDTO.userErrorParam("任务ID不能为空");
        }
        TaskDetailVO detail = taskDao.selectDetail(taskId);
        if (detail == null) {
            return ResponseDTO.userErrorParam("任务不存在或已删除");
        }
        detail.setParticipantList(taskDao.selectParticipantList(taskId));
        detail.setEventList(taskDao.selectEventList(taskId));
        return ResponseDTO.ok(detail);
    }
}
