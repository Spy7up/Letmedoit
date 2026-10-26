package net.lab1024.sa.app.module.helper.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import net.lab1024.sa.app.module.helper.constant.HelperRequestStatusEnum;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 帮手申请
 *
 * @author letmedoit
 */
@Data
@TableName("t_helper_request")
public class HelperRequestEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(type = IdType.AUTO)
    private Long requestId;

    /**
     * 发起人会员ID
     */
    private Long fromMemberId;

    /**
     * 接收人会员ID
     */
    private Long toMemberId;

    /**
     * 附言
     */
    private String applyMessage;

    /**
     * 状态
     *
     * @see HelperRequestStatusEnum
     */
    private Integer status;

    /**
     * 是否删除
     */
    private Boolean deletedFlag;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 更新时间
     */
    private LocalDateTime updateTime;
}
