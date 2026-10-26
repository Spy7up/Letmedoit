package net.lab1024.sa.app.module.agreement.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.agreement.domain.entity.AppAgreementEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 协议正文 DAO
 *
 * @author letmedoit
 */
@Mapper
public interface AppAgreementDao extends BaseMapper<AppAgreementEntity> {
}
