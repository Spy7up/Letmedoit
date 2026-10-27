package net.lab1024.sa.app.module.version.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.version.domain.entity.AppVersionEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 版本 DAO
 * <p>
 * 小程序端只读「当前版本」；后台的列表/新增/发布走 sa-admin 自己的 DAO
 * （sa-admin 不依赖 sa-app，两边共用同一张 t_app_version），设计见 docs/版本管理.md。
 *
 * @author letmedoit
 */
@Mapper
public interface AppVersionDao extends BaseMapper<AppVersionEntity> {

    /**
     * 查当前对外版本
     * <p>
     * 正常只会有一行 current_flag = 1；万一历史上出现两行（手工改库造成），
     * 按发布时间倒序取最新的一条，保证接口永远有确定结果。
     *
     * @param appType     端类型
     * @param deletedFlag 删除标识
     * @return 当前版本，未配置返回 null
     */
    AppVersionEntity queryCurrent(@Param("appType") String appType,
                                  @Param("deletedFlag") Boolean deletedFlag);
}
