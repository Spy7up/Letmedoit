package net.lab1024.sa.app.module.agreement.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.app.module.agreement.domain.entity.AppAgreementRecordEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 协议同意记录 DAO
 *
 * @author letmedoit
 */
@Mapper
public interface AppAgreementRecordDao extends BaseMapper<AppAgreementRecordEntity> {
}
