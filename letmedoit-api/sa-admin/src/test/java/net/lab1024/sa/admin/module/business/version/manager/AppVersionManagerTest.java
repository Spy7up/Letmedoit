package net.lab1024.sa.admin.module.business.version.manager;

import net.lab1024.sa.admin.module.business.version.dao.AppVersionDao;
import net.lab1024.sa.admin.module.business.version.domain.entity.AppVersionEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AppVersionManagerTest {

    private AppVersionDao appVersionDao;

    private AppVersionManager appVersionManager;

    @BeforeEach
    void setUp() {
        appVersionDao = mock(AppVersionDao.class);
        appVersionManager = new AppVersionManager();
        ReflectionTestUtils.setField(appVersionManager, "baseMapper", appVersionDao);
    }

    @Test
    void publishClearsCurrentBeforePublishingTarget() {
        AppVersionEntity target = target();
        when(appVersionDao.publishTarget(7L, "miniapp")).thenReturn(1);

        appVersionManager.publish(target);

        InOrder inOrder = inOrder(appVersionDao);
        inOrder.verify(appVersionDao).clearCurrent("miniapp");
        inOrder.verify(appVersionDao).publishTarget(7L, "miniapp");
    }

    @Test
    void publishFailsWhenTargetCannotBeUpdated() {
        AppVersionEntity target = target();
        when(appVersionDao.publishTarget(7L, "miniapp")).thenReturn(0);

        assertThrows(IllegalStateException.class, () -> appVersionManager.publish(target));

        verify(appVersionDao).clearCurrent("miniapp");
    }

    private AppVersionEntity target() {
        AppVersionEntity target = new AppVersionEntity();
        target.setVersionId(7L);
        target.setAppType("miniapp");
        return target;
    }
}
