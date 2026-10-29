/*
 * 让我做 · 会员报表 API
 *
 * @Author: 让我做
 */
import { getRequest, postRequest } from '/@/lib/axios';

export const letmedoitMemberApi = {
  /**
   * 会员分页查询（含个人指标）
   */
  query: (param) => {
    return postRequest('/member/query', param);
  },

  /**
   * 会员详情：基础信息 + 指标 + 帮手 + 任务 + 近 14 天趋势
   */
  detail: (memberId) => {
    return getRequest(`/member/detail/${memberId}`);
  },
};
