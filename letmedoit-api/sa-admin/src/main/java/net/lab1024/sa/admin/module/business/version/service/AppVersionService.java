package net.lab1024.sa.admin.module.business.version.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.version.constant.AppVersionPlatformEnum;
import net.lab1024.sa.admin.module.business.version.dao.AppVersionDao;
import net.lab1024.sa.admin.module.business.version.domain.entity.AppVersionEntity;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionAddForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionPublishForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionQueryForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionUpdateForm;
import net.lab1024.sa.admin.module.business.version.domain.vo.AppVersionVO;
import net.lab1024.sa.admin.module.business.version.manager.AppVersionManager;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartBeanUtil;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;

/**
 * 小程序版本管理
 *
 * @author letmedoit
 */
@Service
public class AppVersionService {

    @Resource
    private AppVersionDao appVersionDao;

    @Resource
    private AppVersionManager appVersionManager;

    public ResponseDTO<PageResult<AppVersionVO>> query(AppVersionQueryForm queryForm) {
        if (queryForm.getBeginDate() != null && queryForm.getEndDate() != null
                && queryForm.getBeginDate().isAfter(queryForm.getEndDate())) {
            return ResponseDTO.userErrorParam("发布开始日期不能晚于结束日期");
        }
        queryForm.setAppType(trimToNull(queryForm.getAppType()));
        queryForm.setVersion(trimToNull(queryForm.getVersion()));
        if (queryForm.getAppType() != null
                && AppVersionPlatformEnum.getByValue(queryForm.getAppType()) == null) {
            return ResponseDTO.userErrorParam("端类型不合法");
        }
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<AppVersionVO> list = appVersionDao.queryPage(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    public ResponseDTO<String> add(AppVersionAddForm addForm) {
        normalize(addForm);
        if (AppVersionPlatformEnum.getByValue(addForm.getAppType()) == null) {
            return ResponseDTO.userErrorParam("端类型不合法");
        }
        if (appVersionDao.selectByTypeAndVersion(addForm.getAppType(), addForm.getVersion()) != null) {
            return ResponseDTO.userErrorParam("该端下版本号已存在，请新增其他版本号");
        }
        AppVersionEntity entity = SmartBeanUtil.copy(addForm, AppVersionEntity.class);
        entity.setCurrentFlag(Boolean.FALSE);
        entity.setDeletedFlag(Boolean.FALSE);
        try {
            appVersionDao.insert(entity);
        } catch (DuplicateKeyException e) {
            return ResponseDTO.userErrorParam("该端下版本号已存在，请新增其他版本号");
        }
        return ResponseDTO.ok();
    }

    public ResponseDTO<String> update(AppVersionUpdateForm updateForm) {
        normalize(updateForm);
        AppVersionEntity exist = appVersionDao.selectNotDeletedById(updateForm.getVersionId());
        if (exist == null) {
            return ResponseDTO.userErrorParam("版本不存在或已删除");
        }
        if (AppVersionPlatformEnum.getByValue(updateForm.getAppType()) == null) {
            return ResponseDTO.userErrorParam("端类型不合法");
        }
        if (!exist.getAppType().equals(updateForm.getAppType())
                || !exist.getVersion().equals(updateForm.getVersion())) {
            return ResponseDTO.userErrorParam("端类型和版本号创建后不可修改，请新增版本记录");
        }
        AppVersionEntity entity = SmartBeanUtil.copy(updateForm, AppVersionEntity.class);
        int updateCount = appVersionDao.updateInfo(entity);
        if (updateCount != 1) {
            return ResponseDTO.userErrorParam("版本不存在或已删除，请刷新后重试");
        }
        return ResponseDTO.ok();
    }

    public ResponseDTO<String> publish(AppVersionPublishForm publishForm) {
        AppVersionEntity target = appVersionDao.selectNotDeletedById(publishForm.getVersionId());
        if (target == null) {
            return ResponseDTO.userErrorParam("版本不存在或已删除");
        }
        appVersionManager.publish(target);
        return ResponseDTO.ok();
    }

    private void normalize(AppVersionAddForm form) {
        form.setAppType(trimToNull(form.getAppType()));
        form.setVersion(trimToNull(form.getVersion()));
        form.setVersionLabel(trimToNull(form.getVersionLabel()));
        form.setReleaseNote(trimToNull(form.getReleaseNote()));
        form.setMinBaseLib(trimToNull(form.getMinBaseLib()));
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
