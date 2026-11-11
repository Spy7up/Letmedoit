package net.letmedoit.sa.admin.module.business.member.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.letmedoit.sa.admin.constant.AdminSwaggerTagConst;
import net.letmedoit.sa.admin.module.business.member.domain.form.MemberQueryForm;
import net.letmedoit.sa.admin.module.business.member.domain.vo.MemberDetailVO;
import net.letmedoit.sa.admin.module.business.member.domain.vo.MemberVO;
import net.letmedoit.sa.admin.module.business.member.service.MemberService;
import net.letmedoit.sa.base.common.domain.PageResult;
import net.letmedoit.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 小程序会员报表
 *
 * @author letmedoit
 */
@RestController
@Tag(name = AdminSwaggerTagConst.Business.LETMEDOIT_MEMBER)
public class MemberController {

    @Resource
    private MemberService memberService;

    @Operation(summary = "会员分页查询")
    @PostMapping("/member/query")
    @SaCheckPermission("member:query")
    public ResponseDTO<PageResult<MemberVO>> query(@RequestBody @Valid MemberQueryForm queryForm) {
        return memberService.query(queryForm);
    }

    @Operation(summary = "会员详情")
    @GetMapping("/member/detail/{memberId}")
    @SaCheckPermission("member:query")
    public ResponseDTO<MemberDetailVO> detail(@PathVariable Long memberId) {
        return memberService.detail(memberId);
    }
}
