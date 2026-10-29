package net.lab1024.sa.admin.module.business.member.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.member.dao.MemberDao;
import net.lab1024.sa.admin.module.business.member.domain.form.MemberQueryForm;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberDayStatVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberDetailVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberTaskVO;
import net.lab1024.sa.admin.module.business.member.domain.vo.MemberVO;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 小程序会员（只读报表）
 *
 * @Author 1024创新实验室
 */
@Service
public class MemberService {

    /**
     * 详情页趋势天数
     */
    private static final int DETAIL_TREND_DAYS = 14;

    private static final DateTimeFormatter DATE_LABEL_FORMATTER = DateTimeFormatter.ofPattern("MM-dd");

    @Resource
    private MemberDao memberDao;

    public ResponseDTO<PageResult<MemberVO>> query(MemberQueryForm queryForm) {
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<MemberVO> list = memberDao.query(page, queryForm);
        list.forEach(this::fillOnTimeRate);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    public ResponseDTO<MemberDetailVO> detail(Long memberId) {
        if (memberId == null) {
            return ResponseDTO.userErrorParam("会员ID不能为空");
        }
        MemberDetailVO detail = memberDao.selectDetail(memberId);
        if (detail == null) {
            return ResponseDTO.userErrorParam("会员不存在或已注销");
        }
        this.fillOnTimeRate(detail);
        detail.setPendingHelperRequestCount(memberDao.selectPendingHelperRequestCount(memberId));
        detail.setHelperList(memberDao.selectHelperList(memberId));
        detail.setTaskList(memberDao.selectTaskList(memberId));
        detail.setDayStatList(this.buildDayStat(memberId));
        return ResponseDTO.ok(detail);
    }

    /**
     * 近 14 天完成趋势，缺失日期补零，保证前端横轴连续
     */
    private List<MemberDayStatVO> buildDayStat(Long memberId) {
        LocalDate today = LocalDate.now();
        LocalDate startDate = today.minusDays(DETAIL_TREND_DAYS - 1L);
        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = today.plusDays(1).atStartOfDay();
        Map<String, MemberDayStatVO> statMap = memberDao.selectDayStat(memberId, startTime, endTime).stream()
                .collect(Collectors.toMap(MemberDayStatVO::getStatDate, item -> item, (a, b) -> b));

        List<MemberDayStatVO> result = new ArrayList<>(DETAIL_TREND_DAYS);
        for (int i = 0; i < DETAIL_TREND_DAYS; i++) {
            LocalDate date = startDate.plusDays(i);
            MemberDayStatVO item = statMap.get(date.toString());
            if (item == null) {
                item = new MemberDayStatVO();
                item.setStatDate(date.toString());
                item.setCompletedCount(0L);
                item.setOnTimeCount(0L);
            }
            item.setStatDate(date.format(DATE_LABEL_FORMATTER));
            result.add(item);
        }
        return result;
    }

    private void fillOnTimeRate(MemberVO memberVO) {
        memberVO.setOnTimeRate(this.percent(memberVO.getOnTimeCount(), memberVO.getCompletedCount()));
    }

    private BigDecimal percent(Long numerator, Long denominator) {
        if (numerator == null || denominator == null || denominator == 0) {
            return null;
        }
        return BigDecimal.valueOf(numerator).multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(denominator), 2, RoundingMode.HALF_UP);
    }
}
