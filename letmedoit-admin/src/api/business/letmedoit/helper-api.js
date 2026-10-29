/*
 * 让我做 · 帮手关系 API
 *
 * @Author: 让我做
 */
import { postRequest } from '/@/lib/axios';

export const letmedoitHelperApi = {
  /**
   * 帮手关系分页查询（单方向一行，双向双写）
   */
  query: (param) => {
    return postRequest('/helper/query', param);
  },
};
