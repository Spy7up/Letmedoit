/**
 * 三级等保 api 封装
 *
 * @author letmedoit
 */
import { postRequest, getRequest } from '/@/lib/axios';

export const level3ProtectApi = {
  /**
   * 查询 三级等保配置 @author letmedoit
   */
  getConfig: () => {
    return getRequest('/support/protect/level3protect/getConfig');
  },

  /**
   * 更新三级等保配置 @author letmedoit
   */
  updateConfig: (form) => {
    return postRequest('/support/protect/level3protect/updateConfig', form);
  },
};
