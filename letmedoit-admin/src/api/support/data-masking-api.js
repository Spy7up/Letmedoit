/**
 *  数据脱敏api
 *
 * @author letmedoit
 */
import { getRequest } from '/@/lib/axios';

export const dataMaskingApi = {
  /**
   * 查询脱敏数据
   */
  query: () => {
    return getRequest('/support/dataMasking/demo/query');
  },
};
