package net.lab1024.sa.app.module.agreement.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 用户同意记录（法律留痕）
 * <p>
 * 出现纠纷时，"用户在某个时间点同意过某个版本"只能靠这张表举证，
 * 前端勾选状态不具备任何证明力，所以登录成功必须落库。
 *
 * @author letmedoit
 */
@Data
@TableName("t_app_agreement_record")
public class AppAgreementRecordEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long recordId;

    private Long memberId;

    /**
     * 协议类型 user / privacy
     */
    private String agreementType;

    /**
     * 同意的版本号
     */
    private String version;

    private LocalDateTime agreeTime;

    /**
     * 同意时的 IP
     */
    private String ip;

    /**
     * 同意时的客户端标识
     */
    private String userAgent;

    private LocalDateTime createTime;
}
