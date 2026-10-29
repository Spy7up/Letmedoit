/*
 * 让我做 · 小程序反馈 API
 * 数据表是 t_app_feedback，不是框架自带的 t_feedback
 *
 * @Author: 让我做
 */
import { getRequest, postRequest } from '/@/lib/axios';

export const letmedoitFeedbackApi = {
  /**
   * 反馈分页查询
   */
  query: (param) => {
    return postRequest('/appFeedback/query', param);
  },

  /**
   * 反馈详情
   */
  detail: (feedbackId) => {
    return getRequest(`/appFeedback/detail/${feedbackId}`);
  },

  /**
   * 回复并流转状态
   * @param {Object} param { feedbackId, status, replyContent }
   */
  reply: (param) => {
    return postRequest('/appFeedback/reply', param);
  },
};
