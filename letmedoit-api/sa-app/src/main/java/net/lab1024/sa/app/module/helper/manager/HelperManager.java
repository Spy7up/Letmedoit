package net.lab1024.sa.app.module.helper.manager;

import jakarta.annotation.Resource;
import net.lab1024.sa.app.module.helper.constant.HelperRequestStatusEnum;
import net.lab1024.sa.app.module.helper.dao.HelperDao;
import net.lab1024.sa.app.module.helper.dao.HelperRequestDao;
import net.lab1024.sa.app.module.helper.domain.entity.HelperRequestEntity;
import net.lab1024.sa.base.common.exception.BusinessException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 帮手关系事务层
 *
 * @author letmedoit
 */
@Component
public class HelperManager {

    @Resource
    private HelperDao helperDao;

    @Resource
    private HelperRequestDao helperRequestDao;

    /**
     * 双向建立帮手关系
     */
    @Transactional(rollbackFor = Exception.class)
    public void addHelper(Long memberId, Long helperMemberId) {
        LocalDateTime now = LocalDateTime.now();
        helperDao.upsert(memberId, helperMemberId, now);
        helperDao.upsert(helperMemberId, memberId, now);
    }

    /**
     * 同意申请：改状态 + 双向建关系，必须同一个事务
     */
    @Transactional(rollbackFor = Exception.class)
    public void acceptRequest(HelperRequestEntity request) {
        LocalDateTime now = LocalDateTime.now();
        int rows = helperRequestDao.updateStatus(request.getRequestId(),
                HelperRequestStatusEnum.PENDING.getValue(),
                HelperRequestStatusEnum.ACCEPTED.getValue(), now);
        if (rows == 0) {
            throw new BusinessException("该申请已处理");
        }
        helperDao.upsert(request.getFromMemberId(), request.getToMemberId(), now);
        helperDao.upsert(request.getToMemberId(), request.getFromMemberId(), now);
    }

    /**
     * 拒绝申请
     */
    @Transactional(rollbackFor = Exception.class)
    public void rejectRequest(HelperRequestEntity request) {
        int rows = helperRequestDao.updateStatus(request.getRequestId(),
                HelperRequestStatusEnum.PENDING.getValue(),
                HelperRequestStatusEnum.REJECTED.getValue(), LocalDateTime.now());
        if (rows == 0) {
            throw new BusinessException("该申请已处理");
        }
    }

    /**
     * 解除帮手（双向逻辑删除）
     */
    @Transactional(rollbackFor = Exception.class)
    public void removeHelper(Long memberId, Long helperMemberId) {
        helperDao.removeBoth(memberId, helperMemberId, LocalDateTime.now());
    }
}
