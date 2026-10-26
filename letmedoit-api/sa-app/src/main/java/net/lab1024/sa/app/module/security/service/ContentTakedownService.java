package net.lab1024.sa.app.module.security.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.module.member.dao.WxMemberDao;
import net.lab1024.sa.app.module.member.domain.entity.WxMemberEntity;
import net.lab1024.sa.app.module.security.constant.ContentBizTypeEnum;
import net.lab1024.sa.app.module.security.domain.entity.ContentCheckEntity;
import net.lab1024.sa.app.module.task.dao.TaskDao;
import net.lab1024.sa.app.module.task.dao.TaskParticipantDao;
import net.lab1024.sa.app.module.task.domain.entity.TaskEntity;
import net.lab1024.sa.app.module.task.domain.entity.TaskParticipantEntity;
import net.lab1024.sa.app.module.task.service.TaskNoticeService;
import net.lab1024.sa.app.module.task.util.TaskImages;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 违规内容下架
 * <p>
 * 微信图片异步检测是「先放行、后追责」：图片可能已经被人看到了，
 * 收到违规结论后必须把业务数据里指向它的引用清干净，否则违规内容会一直挂在线上。
 * <p>
 * 这里只跟 DAO 打交道（不注入 WxMemberService / TaskService），
 * 避免「业务 Service 依赖内容检测、内容检测又依赖业务 Service」的循环依赖。
 *
 * @author letmedoit
 */
@Slf4j
@Service
public class ContentTakedownService {

    @Resource
    private TaskDao taskDao;

    @Resource
    private TaskParticipantDao taskParticipantDao;

    @Resource
    private WxMemberDao wxMemberDao;

    @Resource
    private TaskNoticeService taskNoticeService;

    /**
     * 按检测记录把违规图片从业务数据里摘掉
     */
    public void takeDown(ContentCheckEntity check) {
        if (check == null || !StringUtils.hasText(check.getMediaUrl())) {
            return;
        }
        String url = check.getMediaUrl();
        ContentBizTypeEnum bizType = ContentBizTypeEnum.getByValue(check.getBizType());
        if (bizType == ContentBizTypeEnum.AVATAR) {
            clearAvatar(check.getMemberId(), url);
            return;
        }
        int taskCount = removeFromTaskImages(url);
        int proofCount = removeFromProofImages(url);
        log.warn("违规图片已下架, url={}, bizType={}, 任务附图{}处, 凭证图{}处", url, check.getBizType(), taskCount, proofCount);
    }

    /**
     * 头像违规：把头像置空，回落到昵称末字色块（前端本来就有兜底）
     */
    private void clearAvatar(Long memberId, String url) {
        if (memberId == null) {
            return;
        }
        int rows = wxMemberDao.update(null, new LambdaUpdateWrapper<WxMemberEntity>()
                .eq(WxMemberEntity::getMemberId, memberId)
                .eq(WxMemberEntity::getAvatar, url)
                .set(WxMemberEntity::getAvatar, null)
                .set(WxMemberEntity::getUpdateTime, LocalDateTime.now()));
        if (rows > 0) {
            log.warn("违规头像已清空, memberId={}", memberId);
        }
    }

    /**
     * 任务附图：从 t_task.images 里摘掉，并通知委托人
     *
     * @return 受影响任务数
     */
    private int removeFromTaskImages(String url) {
        List<TaskEntity> tasks = taskDao.selectList(new LambdaQueryWrapper<TaskEntity>()
                .like(TaskEntity::getImages, url)
                .eq(TaskEntity::getDeletedFlag, Boolean.FALSE));
        int affected = 0;
        for (TaskEntity task : tasks) {
            List<String> images = TaskImages.parse(task.getImages());
            // LIKE 会误命中 URL 前缀相同的其它图片，这里必须精确判一次
            if (!images.remove(url)) {
                continue;
            }
            TaskEntity update = new TaskEntity();
            update.setTaskId(task.getTaskId());
            update.setImages(TaskImages.toJson(images));
            update.setUpdateTime(LocalDateTime.now());
            taskDao.updateById(update);
            taskNoticeService.notifyContentTakedown(task, "任务附图里有违规图片，已自动移除");
            affected++;
        }
        return affected;
    }

    /**
     * 完成凭证图：从 t_task_participant.complete_images 里摘掉
     *
     * @return 受影响记录数
     */
    private int removeFromProofImages(String url) {
        List<TaskParticipantEntity> participants = taskParticipantDao.selectList(
                new LambdaQueryWrapper<TaskParticipantEntity>()
                        .like(TaskParticipantEntity::getCompleteImages, url)
                        .eq(TaskParticipantEntity::getDeletedFlag, Boolean.FALSE));
        int affected = 0;
        for (TaskParticipantEntity participant : participants) {
            List<String> images = TaskImages.parse(participant.getCompleteImages());
            if (!images.remove(url)) {
                continue;
            }
            TaskParticipantEntity update = new TaskParticipantEntity();
            update.setParticipantId(participant.getParticipantId());
            update.setCompleteImages(TaskImages.toJson(images));
            update.setUpdateTime(LocalDateTime.now());
            taskParticipantDao.updateById(update);
            TaskEntity task = taskDao.queryById(participant.getTaskId(), Boolean.FALSE);
            if (task != null) {
                taskNoticeService.notifyContentTakedown(task, "完成凭证里有违规图片，已自动移除");
            }
            affected++;
        }
        return affected;
    }
}
