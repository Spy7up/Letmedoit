/**
 * 接口：加密、解密
 *
 * @author letmedoit
 */
import { postRequest, postEncryptRequest } from '/@/lib/axios';

export const encryptApi = {

  /**
   * 测试 请求加密  @author letmedoit
   */
  testRequestEncrypt: (param) => {
    return postEncryptRequest('/support/apiEncrypt/testRequestEncrypt', param);
  },

  /**
   * 测试 返回加密  @author letmedoit
   */
  testResponseEncrypt: (param) => {
    return postRequest('/support/apiEncrypt/testResponseEncrypt', param);
  },

  /**
   * 测试 请求参数加密和解密、返回数据加密和解密  @author letmedoit
   */
  testDecryptAndEncrypt: (param) => {
    return postEncryptRequest('/support/apiEncrypt/testDecryptAndEncrypt', param);
  },

  /**
   * 测试 数组加解密  @author letmedoit
   */
  testArray : (param) => {
    return postEncryptRequest('/support/apiEncrypt/testArray', param);
  },
  
};
