package net.lab1024.sa.app.module.security.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 内容安全检测记录
 * <p>
 * 每次调用微信接口都留一条：文本检测（trace_id 为空）用于事后追溯，
 * 图片异步检测（trace_id 非空）靠 trace_id 与推送结果对上号。
 *
 * @author letmedoit
 */
@Data
@TableName("t_content_check")
public class ContentCheckEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long checkId;

    /**
     * 微信异步检测任务ID，文本检测为空
     */
    private String traceId;

    /**
     * 提交检测的会员
     */
    private Long memberId;

    /**
     * 业务来源：avatar / task_image / task_proof
     *
     * @see net.lab1024.sa.app.module.security.constant.ContentBizTypeEnum
     */
    private String bizType;

    /**
     * 场景值：1 资料 2 评论 3 论坛 4 社交日志
     */
    private Integer scene;

    /**
     * 被检测的图片地址，文本检测为空
     */
    private String mediaUrl;

    /**
     * 1 音频 2 图片
     */
    private Integer mediaType;

    /**
     * 文本摘要，排查时看得懂是什么内容
     */
    private String contentBrief;

    /**
     * 检测状态
     *
     * @see net.lab1024.sa.app.module.security.constant.ContentCheckStatusEnum
     */
    private Integer status;

    /**
     * 微信返回的命中标签：100 正常；20001 时政；20002 色情；20006 违法；21000 其他
     */
    private Integer label;

    /**
     * 微信返回的建议：pass / review / risky
     */
    private String suggest;

    /**
     * 错误信息
     */
    private String errMsg;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
