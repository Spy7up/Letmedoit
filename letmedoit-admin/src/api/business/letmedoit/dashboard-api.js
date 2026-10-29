/*
 * 让我做 · 运营概览 API
 *
 * @Author: 让我做
 */
import { getRequest, postRequest } from '/@/lib/axios';

export const letmedoitDashboardApi = {
  /**
   * 总览指标（会员/帮手/任务/准时率/待处理反馈）
   */
  overview: () => {
    return getRequest('/dashboard/overview');
  },

  /**
   * 趋势：注册会员、新建任务、完成任务
   * @param {Number} days 7~90
   */
  trend: (days) => {
    return postRequest('/dashboard/trend', { days });
  },
};
