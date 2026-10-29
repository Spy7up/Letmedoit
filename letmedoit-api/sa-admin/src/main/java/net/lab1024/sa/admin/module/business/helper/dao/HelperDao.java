package net.lab1024.sa.admin.module.business.helper.dao;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.helper.domain.form.HelperQueryForm;
import net.lab1024.sa.admin.module.business.helper.domain.vo.HelperVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 帮手关系（只读）
 *
 * @Author 1024创新实验室
 */
@Mapper
public interface HelperDao {

    List<HelperVO> query(Page<?> page, @Param("query") HelperQueryForm query);
}
