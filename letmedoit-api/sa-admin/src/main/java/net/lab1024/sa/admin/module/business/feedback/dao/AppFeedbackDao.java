package net.lab1024.sa.admin.module.business.feedback.dao;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.feedback.domain.form.AppFeedbackQueryForm;
import net.lab1024.sa.admin.module.business.feedback.domain.vo.AppFeedbackVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 小程序反馈 t_app_feedback（注意不是框架的 t_feedback）
 *
 * @Author 1024创新实验室
 */
@Mapper
public interface AppFeedbackDao {

    List<AppFeedbackVO> query(Page<?> page, @Param("query") AppFeedbackQueryForm query);

    AppFeedbackVO selectDetail(@Param("feedbackId") Long feedbackId);

    Integer selectStatus(@Param("feedbackId") Long feedbackId);

    /**
     * 按期望旧状态更新，影响行数为 0 表示已被他人处理
     */
    int updateReply(@Param("feedbackId") Long feedbackId, @Param("oldStatus") Integer oldStatus,
                    @Param("status") Integer status, @Param("replyContent") String replyContent,
                    @Param("employeeId") Long employeeId);
}
