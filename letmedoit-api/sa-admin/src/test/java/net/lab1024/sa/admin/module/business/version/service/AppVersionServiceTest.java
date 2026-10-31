package net.lab1024.sa.admin.module.business.version.service;

import net.lab1024.sa.admin.module.business.version.dao.AppVersionDao;
import net.lab1024.sa.admin.module.business.version.domain.entity.AppVersionEntity;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionAddForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionPublishForm;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionUpdateForm;
import net.lab1024.sa.admin.module.business.version.manager.AppVersionManager;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AppVersionServiceTest {

    @InjectMocks
    private AppVersionService appVersionService;

    @Mock
    private AppVersionDao appVersionDao;

    @Mock
    private AppVersionManager appVersionManager;

    @Test
    void addCreatesUnpublishedRecord() {
        AppVersionAddForm form = validAddForm();
        when(appVersionDao.selectByTypeAndVersion("miniapp", "1.1.0")).thenReturn(null);

        ResponseDTO<String> response = appVersionService.add(form);

        assertTrue(response.getOk());
        ArgumentCaptor<AppVersionEntity> captor = ArgumentCaptor.forClass(AppVersionEntity.class);
        verify(appVersionDao).insert(captor.capture());
        assertFalse(captor.getValue().getCurrentFlag());
        assertFalse(captor.getValue().getDeletedFlag());
        assertEquals("miniapp", captor.getValue().getAppType());
        assertEquals("1.1.0", captor.getValue().getVersion());
    }

    @Test
    void addRejectsDuplicateVersion() {
        AppVersionAddForm form = validAddForm();
        when(appVersionDao.selectByTypeAndVersion("miniapp", "1.1.0")).thenReturn(new AppVersionEntity());

        ResponseDTO<String> response = appVersionService.add(form);

        assertFalse(response.getOk());
        assertEquals("该端下版本号已存在，请新增其他版本号", response.getMsg());
        verify(appVersionDao, never()).insert(any(AppVersionEntity.class));
    }

    @Test
    void updateRejectsVersionNumberChange() {
        AppVersionEntity exist = versionEntity(7L, "1.0.0");
        when(appVersionDao.selectNotDeletedById(7L)).thenReturn(exist);
        AppVersionUpdateForm form = new AppVersionUpdateForm();
        form.setVersionId(7L);
        form.setAppType("miniapp");
        form.setVersion("1.1.0");
        form.setForceUpdateFlag(false);

        ResponseDTO<String> response = appVersionService.update(form);

        assertFalse(response.getOk());
        assertEquals("端类型和版本号创建后不可修改，请新增版本记录", response.getMsg());
        verify(appVersionDao, never()).updateInfo(any());
    }

    @Test
    void publishUsesTransactionalManager() {
        AppVersionEntity target = versionEntity(7L, "1.1.0");
        when(appVersionDao.selectNotDeletedById(7L)).thenReturn(target);
        AppVersionPublishForm form = new AppVersionPublishForm();
        form.setVersionId(7L);

        ResponseDTO<String> response = appVersionService.publish(form);

        assertTrue(response.getOk());
        verify(appVersionManager).publish(target);
    }

    @Test
    void publishRejectsMissingRecord() {
        when(appVersionDao.selectNotDeletedById(7L)).thenReturn(null);
        AppVersionPublishForm form = new AppVersionPublishForm();
        form.setVersionId(7L);

        ResponseDTO<String> response = appVersionService.publish(form);

        assertFalse(response.getOk());
        verifyNoInteractions(appVersionManager);
    }

    private AppVersionAddForm validAddForm() {
        AppVersionAddForm form = new AppVersionAddForm();
        form.setAppType("miniapp");
        form.setVersion("1.1.0");
        form.setVersionLabel("v1.1.0");
        form.setForceUpdateFlag(false);
        return form;
    }

    private AppVersionEntity versionEntity(Long id, String version) {
        AppVersionEntity entity = new AppVersionEntity();
        entity.setVersionId(id);
        entity.setAppType("miniapp");
        entity.setVersion(version);
        entity.setDeletedFlag(false);
        entity.setCurrentFlag(false);
        return entity;
    }
}
