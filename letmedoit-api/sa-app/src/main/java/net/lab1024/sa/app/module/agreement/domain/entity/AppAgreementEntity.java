package net.lab1024.sa.app.module.agreement.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 用户协议 / 隐私政策
 * <p>
 * 同一类型允许多版本并存，只有 enabled_flag = 1 且已到生效时间的
 * 最新一条生效，用户端读到的就是它。
 *
 * @author letmedoit
 */
@Data
@TableName("t_app_agreement")
public class AppAgreementEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long agreementId;

    /**
     * 类型：user 用户协议 / privacy 隐私政策
     *
     * @see net.lab1024.sa.app.module.agreement.constant.AgreementTypeEnum
     */
    private String type;

    private String title;

    /**
     * 版本号，如 1.0.0
     */
    private String version;

    /**
     * 正文，纯文本，# 开头为标题行
     */
    private String content;

    /**
     * 生效时间
     */
    private LocalDateTime effectiveTime;

    /**
     * 是否启用
     */
    private Boolean enabledFlag;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
