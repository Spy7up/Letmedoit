package net.lab1024.sa.admin.module.business.version.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 小程序版本记录
 *
 * @author letmedoit
 */
@Data
@TableName("t_app_version")
public class AppVersionEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long versionId;

    private String appType;

    private String version;

    private String versionLabel;

    private String releaseNote;

    private LocalDateTime releaseTime;

    private String minBaseLib;

    private Boolean forceUpdateFlag;

    private Boolean currentFlag;

    private Boolean deletedFlag;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
