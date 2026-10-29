package net.lab1024.sa.admin.module.business.helper.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.helper.dao.HelperDao;
import net.lab1024.sa.admin.module.business.helper.domain.form.HelperQueryForm;
import net.lab1024.sa.admin.module.business.helper.domain.vo.HelperVO;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 帮手关系（只读）
 *
 * @Author 1024创新实验室
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
