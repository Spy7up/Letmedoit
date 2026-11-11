package net.letmedoit.sa.base.module.support.codegenerator.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.letmedoit.sa.base.module.support.codegenerator.domain.entity.CodeGeneratorConfigEntity;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Component;

/**
 * 表的 代码生成配置 Dao
 * @author letmedoit
 */
@Mapper
public interface CodeGeneratorConfigDao extends BaseMapper<CodeGeneratorConfigEntity> {

}