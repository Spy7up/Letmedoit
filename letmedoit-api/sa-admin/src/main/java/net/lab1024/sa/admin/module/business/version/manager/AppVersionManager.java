package net.lab1024.sa.admin.module.business.version.manager;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import net.lab1024.sa.admin.module.business.version.dao.AppVersionDao;
import net.lab1024.sa.admin.module.business.version.domain.entity.AppVersionEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 版本多步写事务
 *
 * @author letmedoit
 */
@Service
public class AppVersionManager extends ServiceImpl<AppVersionDao, AppVersionEntity> {

    /**
     * 同一端先下线旧版本，再发布目标版本；任一步失败都回滚。
     */
    @Transactional(rollbackFor = Exception.class)
    public void publish(AppVersionEntity target) {
        baseMapper.clearCurrent(target.getAppType());
        int updateCount = baseMapper.publishTarget(target.getVersionId(), target.getAppType());
        if (updateCount != 1) {
            throw new IllegalStateException("版本发布失败，目标版本不存在或已删除");
        }
    }
}
