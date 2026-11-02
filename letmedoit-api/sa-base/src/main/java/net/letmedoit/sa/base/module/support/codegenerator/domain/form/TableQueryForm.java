package net.letmedoit.sa.base.module.support.codegenerator.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import net.letmedoit.sa.base.common.domain.PageParam;


/**
 * 查询表数据
 *
 * @author letmedoit
 */
@Data
public class TableQueryForm extends PageParam {

    @Schema(description = "表名关键字")
    private String tableNameKeywords;

}
