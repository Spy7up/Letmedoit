package net.letmedoit.sa.admin.module.business.helper.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.letmedoit.sa.admin.module.business.helper.dao.HelperDao;
import net.letmedoit.sa.admin.module.business.helper.domain.form.HelperQueryForm;
import net.letmedoit.sa.admin.module.business.helper.domain.vo.HelperVO;
import net.letmedoit.sa.base.common.domain.PageResult;
import net.letmedoit.sa.base.common.domain.ResponseDTO;
import net.letmedoit.sa.base.common.util.SmartPageUtil;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 帮手关系（只读）
 *
 * @author letmedoit
 */
@Service
public class HelperService {

    @Resource
    private HelperDao helperDao;

    public ResponseDTO<PageResult<HelperVO>> query(HelperQueryForm queryForm) {
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<HelperVO> list = helperDao.query(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }
}
