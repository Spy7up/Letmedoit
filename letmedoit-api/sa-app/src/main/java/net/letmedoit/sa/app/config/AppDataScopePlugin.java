package net.letmedoit.sa.app.config;

import net.letmedoit.sa.base.common.domain.DataScopePlugin;
import org.apache.ibatis.executor.statement.StatementHandler;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Signature;
import org.springframework.stereotype.Component;

import java.sql.Connection;

/**
 * 小程序端数据权限插件占位
 * <p>
 * sa-base 的 DataSourceConfig 依赖 DataScopePlugin，而真实实现（MyBatisPlugin）在 sa-admin 中。
 * 小程序端是 C 端会员，不存在部门数据权限，这里直放行，不拼接任何 SQL。
 *
 * @author letmedoit
 */
@Component
@Intercepts({@Signature(type = StatementHandler.class, method = "prepare", args = {Connection.class, Integer.class})})
public class AppDataScopePlugin extends DataScopePlugin {

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        return invocation.proceed();
    }
}
