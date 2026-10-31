package net.lab1024.sa.admin.module.business.version.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;

import java.time.LocalDate;

/**
 * 版本分页查询
 *
 * @author letmedoit
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "版本分页查询")
public class AppVersionQueryForm extends PageParam {

    @Size(max = 16, message = "端类型长度不能超过16个字符")
    private String appType;

    @Size(max = 32, message = "版本号长度不能超过32个字符")
    private String version;

    @Schema(description = "是否当前版本；不传查询全部")
    private Boolean currentFlag;

    @Schema(description = "发布开始日期，含当天")
    private LocalDate beginDate;

    @Schema(description = "发布结束日期，含当天")
    private LocalDate endDate;
}
