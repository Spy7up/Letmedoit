package net.letmedoit.sa.base.module.support.reload;

import jakarta.annotation.Resource;
import net.letmedoit.sa.base.common.util.SmartBeanUtil;
import net.letmedoit.sa.base.module.support.reload.core.AbstractSmartReloadCommand;
import net.letmedoit.sa.base.module.support.reload.core.domain.SmartReloadItem;
import net.letmedoit.sa.base.module.support.reload.core.domain.SmartReloadResult;
import net.letmedoit.sa.base.module.support.reload.dao.ReloadItemDao;
import net.letmedoit.sa.base.module.support.reload.dao.ReloadResultDao;
import net.letmedoit.sa.base.module.support.reload.domain.ReloadItemEntity;
import net.letmedoit.sa.base.module.support.reload.domain.ReloadResultEntity;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * reload 操作
 *
 * @author letmedoit
 */
@Component
public class ReloadCommand extends AbstractSmartReloadCommand {

    @Resource
    private ReloadItemDao reloadItemDao;

    @Resource
    private ReloadResultDao reloadResultDao;

    /**
     * 读取数据库中SmartReload项
     *
     * @return List<ReloadItem>
     */
    @Override
    public List<SmartReloadItem> readReloadItem() {
        List<ReloadItemEntity> reloadItemEntityList = reloadItemDao.selectList(null);
        return SmartBeanUtil.copyList(reloadItemEntityList, SmartReloadItem.class);
    }


    /**
     * 保存reload结果
     *
     * @param smartReloadResult
     */
    @Override
    public void handleReloadResult(SmartReloadResult smartReloadResult) {
        ReloadResultEntity reloadResultEntity = SmartBeanUtil.copy(smartReloadResult, ReloadResultEntity.class);
        reloadResultDao.insert(reloadResultEntity);
    }
}
