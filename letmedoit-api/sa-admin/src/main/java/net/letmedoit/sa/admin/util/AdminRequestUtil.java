package net.letmedoit.sa.admin.util;

import net.letmedoit.sa.admin.module.system.login.domain.RequestEmployee;
import net.letmedoit.sa.base.common.domain.RequestUser;
import net.letmedoit.sa.base.common.util.SmartRequestUtil;

/**
 * admin 端的请求工具类
 *
 * @author letmedoit
 */
public final class AdminRequestUtil {


    public static RequestEmployee getRequestUser() {
        return (RequestEmployee) SmartRequestUtil.getRequestUser();
    }

    public static Long getRequestUserId() {
        RequestUser requestUser = getRequestUser();
        return null == requestUser ? null : requestUser.getUserId();
    }


}
