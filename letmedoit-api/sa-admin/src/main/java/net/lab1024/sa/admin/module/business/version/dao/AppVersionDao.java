package net.lab1024.sa.admin.module.business.version.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.version.domain.entity.AppVersionEntity;
import net.lab1024.sa.admin.module.business.version.domain.form.AppVersionQueryForm;
import net.lab1024.sa.admin.module.business.version.domain.vo.AppVersionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 小程序版本 DAO
 *
 * @author letmedoit
 */
@Mapper
public interface AppVersionDao extends BaseMapper<AppVersionEntity> {

    List<AppVersionVO> queryPage(Page<?> page, @Param("query") AppVersionQueryForm query);

    AppVersionEntity selectNotDeletedById(@Param("versionId") Long versionId);

    /**
     * 唯一键不含 deleted_flag，因此查重必须包含已删除记录。
     */
    AppVersionEntity selectByTypeAndVersion(@Param("appType") String appType, @Param("version") String version);

    int updateInfo(AppVersionEntity entity);

    int clearCurrent(@Param("appType") String appType);

    int publishTarget(@Param("versionId") Long versionId, @Param("appType") String appType);
}
