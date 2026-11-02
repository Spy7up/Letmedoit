/*
 *  登录
 *
 * @author letmedoit
 */
import { getRequest, postRequest } from '/@/lib/axios';

export const loginApi = {
  /**
   * 登录 @author letmedoit
   */
  login: (param) => {
    return postRequest('/login', param);
  },

  /**
   * 退出登录 @author letmedoit
   */
  logout: () => {
    return getRequest('/login/logout');
  },

  /**
   * 获取验证码 @author letmedoit
   */
  getCaptcha: () => {
    return getRequest('/login/getCaptcha');
  },

  /**
   * 获取登录信息 @author letmedoit
   */
  getLoginInfo: () => {
    return getRequest('/login/getLoginInfo');
  },

  /**
   * 获取邮箱登录验证码 @author letmedoit
   */
  sendLoginEmailCode: (loginName) => {
    return getRequest(`/login/sendEmailCode/${loginName}`);
  },

  /**
   * 获取双因子登录标识 @author letmedoit
   */
  getTwoFactorLoginFlag: () => {
    return getRequest('/login/getTwoFactorLoginFlag');
  },
};
