package net.lab1024.sa.app.module.security.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.security.domain.entity.ContentCheckEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 内容安全检测记录 DAO
 * <p>
 * 查询条件都用 LambdaQueryWrapper 表达，不需要额外 XML。
 *
 * @author letmedoit
 */
@Mapper
public interface ContentCheckDao extends BaseMapper<ContentCheckEntity> {
}
