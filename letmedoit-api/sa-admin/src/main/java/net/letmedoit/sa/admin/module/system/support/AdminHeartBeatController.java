package net.letmedoit.sa.admin.module.system.support;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.letmedoit.sa.base.common.controller.SupportBaseController;
import net.letmedoit.sa.base.common.domain.PageResult;
import net.letmedoit.sa.base.common.domain.ResponseDTO;
import net.letmedoit.sa.base.constant.SwaggerTagConst;
import net.letmedoit.sa.base.module.support.heartbeat.HeartBeatService;
import net.letmedoit.sa.base.module.support.heartbeat.domain.HeartBeatRecordQueryForm;
import net.letmedoit.sa.base.module.support.heartbeat.domain.HeartBeatRecordVO;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 心跳记录
 *
 * @author letmedoit
 */
@Tag(name = SwaggerTagConst.Support.HEART_BEAT)
@RestController
public class AdminHeartBeatController extends SupportBaseController {

    @Resource
    private HeartBeatService heartBeatService;

    @PostMapping("/heartBeat/query")
    @Operation(summary = "查询心跳记录")
    public ResponseDTO<PageResult<HeartBeatRecordVO>> query(@RequestBody @Valid HeartBeatRecordQueryForm pageParam) {
        return heartBeatService.pageQuery(pageParam);
    }

}
