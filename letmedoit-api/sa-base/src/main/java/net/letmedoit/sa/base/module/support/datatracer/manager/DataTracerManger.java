package net.letmedoit.sa.base.module.support.datatracer.manager;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import net.letmedoit.sa.base.module.support.datatracer.dao.DataTracerDao;
import net.letmedoit.sa.base.module.support.datatracer.domain.entity.DataTracerEntity;
import org.springframework.stereotype.Service;

/**
 * manager层
 *
 * @author letmedoit
 */
@Service
public class DataTracerManger extends ServiceImpl<DataTracerDao, DataTracerEntity> {
}
