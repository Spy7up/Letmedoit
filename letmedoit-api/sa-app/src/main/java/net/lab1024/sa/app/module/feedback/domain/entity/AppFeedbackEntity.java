package net.lab1024.sa.app.module.feedback.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import net.lab1024.sa.app.module.feedback.constant.FeedbackStatusEnum;
import net.lab1024.sa.app.module.feedback.constant.FeedbackTypeEnum;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 问题与反馈
 * <p>
 * 字段按「后台客服工作台」的需要设计：除了用户填的内容，还预留了处理状态、
 * 处理人、处理回复与回复时间，后台接入时不需要再改表。
 *
 * @author letmedoit
 */
@Data
@TableName("t_app_feedback")
public class AppFeedbackEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 反馈ID
     */
    @TableId(type = IdType.AUTO)
    private Long feedbackId;

    /**
     * 提交人会员ID
     */
    private Long memberId;

    /**
     * 反馈类型
     *
     * @see FeedbackTypeEnum
     */
    private Integer type;

    /**
     * 反馈内容
     */
    private String content;

    /**
     * 反馈图片，JSON 数组字符串，最多 3 张公网 URL
     */
    private String images;

    /**
     * 联系方式（选填，用户没填就是 null）
     */
    private String contact;

    /**
     * 处理状态
     *
     * @see FeedbackStatusEnum
     */
    private Integer status;

    /**
     * 处理回复（后台填写后在「我的反馈」里展示，本期只落库）
     */
    private String replyContent;

    /**
     * 处理人（后台员工ID，本期不写入）
     */
    private Long replyMemberId;

    /**
     * 回复时间
     */
    private LocalDateTime replyTime;

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
