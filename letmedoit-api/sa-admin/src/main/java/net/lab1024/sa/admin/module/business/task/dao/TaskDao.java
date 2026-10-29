package net.lab1024.sa.admin.module.business.task.dao;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.task.domain.form.TaskQueryForm;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskDetailVO;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskEventVO;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskParticipantVO;
import net.lab1024.sa.admin.module.business.task.domain.vo.TaskVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 任务（只读）
 *
 * @Author 1024创新实验室
 */
@Mapper
public interface TaskDao {

    List<TaskVO> query(Page<?> page, @Param("query") TaskQueryForm query);

    TaskDetailVO selectDetail(@Param("taskId") Long taskId);

    List<TaskParticipantVO> selectParticipantList(@Param("taskId") Long taskId);

    List<TaskEventVO> selectEventList(@Param("taskId") Long taskId);
}
