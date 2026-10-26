# Docker 部署（服务器侧 env 文件）

> 配置文件里的凭证已全部清空，数据库 / Redis / COS / 微信的密钥**只能从环境变量注入**。
> 这里把 env 文件放在服务器上，不随代码走。

---

## 1. 文件放哪

服务器上的部署目录（jar 和 Dockerfile 同级）：

```
/opt/letmedoit/
├── sa-app-prod-3.0.0.jar    # 后端 jar
├── Dockerfile
├── deploy.sh
├── .env                     # ← 环境变量，chmod 600，不进仓库
└── logs/                    # 挂载到容器 /app/logs
```

`.env` 只存在于服务器。仓库里只提交模板 `letmedoit-api/deploy/.env.prod.example`。

---

## 2. 创建 .env

```bash
cd /opt/letmedoit
cp .env.prod.example .env     # 或从仓库里拷模板
vi .env                       # 填 DB_HOST / DB_USERNAME / DB_PASSWORD / REDIS_HOST 等
chmod 600 .env                # 只有属主可读写
```

必填（缺了直接起不来）：

| 变量 | 说明 |
|---|---|
| `DB_HOST` `DB_USERNAME` `DB_PASSWORD` | MySQL，`DB_NAME` 生产是 `letmedoit` |
| `REDIS_HOST` | Redis，无密码可留空 `REDIS_PASSWORD=` |
| `COS_SECRET_ID` `COS_SECRET_KEY` | cloud 模式上传图片必需 |
| `WX_MINIAPP_APPID` `WX_MINIAPP_SECRET` | 小程序登录必需 |

---

## 3. deploy.sh 怎么注入

已经在脚本里改好，核心是这一行：

```bash
docker run -d \
  --name sa-app \
  -p 8081:1025 \
  -e TZ=Asia/Shanghai \
  --env-file "$ENV_FILE" \
  -e LOCALPATH=/app \
  -v /home/pi/myapp/logs:/app/logs \
  sa-app:版本号
```

- `--env-file ./.env`：Docker 原生读取，一行一个 `KEY=VALUE`，**值不做 shell 解析**，密码里有 `$ ! # 空格` 都不用转义。
- `-e LOCALPATH=/app`：不设的话日志会写到容器内 `/home/logs/...`，**挂载的 `/app/logs` 就是空的**。
- 回滚分支的 `docker run` 也带同样的参数，不会出现回滚后连不上库。

前置检查已加：env 文件不存在、是空的、含 CRLF、缺 `DB_HOST`/`DB_USERNAME`/`DB_PASSWORD`/`REDIS_HOST` 时**直接报错退出**，不会在容器起来后才发现问题。

---

## 4. 部署

```bash
chmod +x deploy.sh
./deploy.sh                 # 自动用时间戳做版本号
./deploy.sh v1.2.3          # 指定版本号
```

验证变量真的进去了：

```bash
docker exec sa-app env | grep -E 'DB_HOST|REDIS_HOST'   # 能打印出来说明注入成功
docker logs -f sa-app | head -30                        # 找 "Started AppApplication"
```

---

## 5. 四个高频坑

**① 用错 jar 包**
maven profile 是打包时固化的：`-Pdev` 出的是 dev 配置（库 `smart_admin_v3`、p6spy 驱动），`-Pprod` 才是生产（库 `letmedoit`）。

```bash
mvn -o -pl sa-app -am package -DskipTests -Pprod
# 产物：sa-app/target/sa-app-prod-3.0.0.jar
```

jar 名**只需要改 `deploy.sh` 里的 `JAR_PATH` 一处**：脚本会用 `--build-arg JAR_FILE=xxx` 把它传给 Dockerfile，`Dockerfile` 里的 `ARG JAR_FILE` 自动接收，不用两边同步。
临时用 dev 包联调时，把 `JAR_PATH` 改成 `./sa-app-dev-3.0.0.jar` 即可。

**② CRLF 换行**
Windows 上编辑过的 `.env` 传到服务器，每行末尾带 `\r`，密码看起来一样却报 `Access denied`。脚本已检测并拦截，修复：

```bash
dos2unix .env     # 或 sed -i 's/\r$//' .env
```

**③ 密码含特殊字符**
`--env-file` 不解析引号，所以 `DB_PASSWORD=abc"123` 的值就是 `abc"123`，**不要给值加引号**（加了引号引号会成为密码的一部分）。

**④ 日志目录权限**
容器内以 root 跑，挂载目录若属主不对可能写不进去：

```bash
mkdir -p /home/pi/myapp/logs && chmod 777 /home/pi/myapp/logs
```

---

## 6. 安全提醒

- `--env-file` 注入的变量会出现在 `docker inspect sa-app` 里，**同机有 docker 权限的人都能看到**。至少保证只有你自己在 `docker` 组，`.env` 用 `chmod 600`。
- 不要把 `.env` 放进构建上下文。当前 `Dockerfile` 只 `COPY` jar，是安全的；将来若改成 `COPY . .`，密钥会被打进镜像层。
- 更严格的做法：用 `docker secret` 或启动时从 KMS/密钥管理服务拉取，`--env-file` 的好处是简单直观，适用于单机自建。
