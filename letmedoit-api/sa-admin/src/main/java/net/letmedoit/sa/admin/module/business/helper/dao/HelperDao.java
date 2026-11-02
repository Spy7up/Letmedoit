package net.letmedoit.sa.admin.module.business.helper.dao;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.letmedoit.sa.admin.module.business.helper.domain.form.HelperQueryForm;
import net.letmedoit.sa.admin.module.business.helper.domain.vo.HelperVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 帮手关系（只读）
 *
 * @author letmedoit
 */
@Mapper
public interface HelperDao {

    List<HelperVO> query(Page<?> page, @Param("query") HelperQueryForm query);
}
