/*
 * 让我做 · 任务报表 API
 *
 * @Author: 让我做
 */
import { getRequest, postRequest } from '/@/lib/axios';

export const letmedoitTaskApi = {
  /**
   * 任务分页查询
   */
  query: (param) => {
    return postRequest('/task/query', param);
  },

  /**
   * 任务详情：参与者、完成凭证、事件时间线
   */
  detail: (taskId) => {
    return getRequest(`/task/detail/${taskId}`);
  },
};
