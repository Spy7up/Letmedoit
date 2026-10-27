package net.lab1024.sa.app.module.version.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.app.module.version.dao.AppVersionDao;
import net.lab1024.sa.app.module.version.domain.entity.AppVersionEntity;
import net.lab1024.sa.app.module.version.domain.vo.AppVersionVO;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * 版本号
 * <p>
 * 小程序里所有版本的文字（「我的」页页脚、关于弹窗）都只从这里取，
 * 代码里不再出现任何写死的版本号 —— 改版本只需要后台发一条记录。
 * <p>
 * 没配版本时返回空对象而不是抛异常：版本号只影响展示，
 * 不能因为漏跑一条 SQL 就让「我的」页打不开。
 *
 * @author letmedoit
 */
@Slf4j
@Service
public class AppVersionService {

    @Resource
    private AppVersionDao appVersionDao;

    /**
     * 当前对外版本
     *
     * @param appType 端类型，见 VersionPlatformEnum
     * @return 版本信息；未配置时 version / versionLabel 为空串
     */
    public AppVersionVO current(String appType) {
        AppVersionVO vo = new AppVersionVO();
        vo.setAppType(appType);
        vo.setVersion("");
        vo.setVersionLabel("");
        vo.setReleaseNote("");
        vo.setForceUpdateFlag(Boolean.FALSE);

        AppVersionEntity entity = appVersionDao.queryCurrent(appType, Boolean.FALSE);
        if (entity == null) {
            log.warn("版本未配置, appType={}，请执行 docs/sql/init/letmedoit_init.sql（或 updates/2026-10-27/02_version.sql）", appType);
            return vo;
        }
        vo.setVersion(entity.getVersion());
        // 展示串优先用后台填的（可能写成「v1.1.0 内测」），没填就用 v + 版本号
        vo.setVersionLabel(StringUtils.hasText(entity.getVersionLabel())
                ? entity.getVersionLabel()
                : "v" + entity.getVersion());
        vo.setReleaseNote(entity.getReleaseNote());
        vo.setReleaseTime(entity.getReleaseTime());
        vo.setMinBaseLib(entity.getMinBaseLib());
        vo.setForceUpdateFlag(Boolean.TRUE.equals(entity.getForceUpdateFlag()));
        return vo;
    }
}
