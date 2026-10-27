package net.lab1024.sa.app.module.notice.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.app.module.notice.domain.entity.NoticeEntity;
import net.lab1024.sa.app.module.notice.domain.form.NoticeQueryForm;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 服务通知 DAO
 *
 * @author letmedoit
 */
@Mapper
public interface NoticeDao extends BaseMapper<NoticeEntity> {

    /**
     * 批量插入通知
     *
     * @param list 通知实体
     * @return 受影响行数
     */
    int insertBatch(@Param("list") List<NoticeEntity> list);

    /**
     * 分页查询我的通知
     *
     * @param query    查询条件
     * @param memberId 当前会员
     * @param page     分页
     * @return 通知列表
     */
    List<NoticeEntity> queryPage(@Param("query") NoticeQueryForm query,
                                 @Param("memberId") Long memberId,
                                 Page<?> page);

    /**
     * 逻辑删除某条任务的全部通知（任务被删除时调用）
     *
     * @param taskId     任务ID
     * @param updateTime 更新时间
     * @return 受影响行数
     */
    int logicDeleteByTaskId(@Param("taskId") Long taskId, @Param("updateTime") LocalDateTime updateTime);

    /**
     * 未读数
     *
     * @param memberId 当前会员
     * @return 未读条数
     */
    Integer countUnread(@Param("memberId") Long memberId);

    /**
     * 标记已读
     *
     * @param memberId  当前会员
     * @param noticeIds 指定通知，为空时表示全部
     * @param updateTime 更新时间
     * @return 受影响行数
     */
    int updateRead(@Param("memberId") Long memberId,
                   @Param("noticeIds") List<Long> noticeIds,
                   @Param("updateTime") LocalDateTime updateTime);
}
