/*
 * 首页api
 *
 * @author letmedoit
 */
import { getRequest } from '/@/lib/axios';

export const homeApi = {
  /**
   * @description: 首页-金额统计（业绩、收款、订单数等） @author letmedoit
   */
  homeAmountStatistics: () => {
    return getRequest('/home/amount/statistics');
  },
  /**
   * @description: 首页-待办信息 @author letmedoit
   */
  homeWaitHandle: () => {
    return getRequest('home/wait/handle');
  },
};
