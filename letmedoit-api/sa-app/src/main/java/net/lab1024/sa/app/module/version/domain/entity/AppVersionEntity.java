package net.lab1024.sa.app.module.version.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 版本记录
 * <p>
 * 一整张表只为一件事：让「小程序里显示的版本号」不再写死在代码里。
 * 每次发版后台新增一条并置为当前版本，前端打开页面读 /api/version/current 即可。
 * <p>
 * 字段按后台版本管理页的需要设计：历史版本留档（可做更新日志）、
 * 预留强制更新与最低基础库（本期只落库，不参与逻辑）。
 *
 * @author letmedoit
 */
@Data
@TableName("t_app_version")
public class AppVersionEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(type = IdType.AUTO)
    private Long versionId;

    /**
     * 端类型，见 VersionPlatformEnum，默认 miniapp
     */
    private String appType;

    /**
     * 版本号，如 1.1.0（不带 v，便于比较大小）
     */
    private String version;

    /**
     * 展示用版本号，如 v1.1.0；为空时由服务端用「v + version」兜底
     */
    private String versionLabel;

    /**
     * 更新说明，展示在「关于」弹窗里
     */
    private String releaseNote;

    /**
     * 发布时间
     */
    private LocalDateTime releaseTime;

    /**
     * 最低基础库版本（预留：低于它提示升级微信）
     */
    private String minBaseLib;

    /**
     * 是否强制更新（预留：本期前端不读取）
     */
    private Boolean forceUpdateFlag;

    /**
     * 是否当前对外版本；同一端只应有一行为 true
     */
    private Boolean currentFlag;

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
