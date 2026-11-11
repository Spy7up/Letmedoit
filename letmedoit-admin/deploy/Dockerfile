# letmedoit 管理后台（sa-admin 前端）镜像
# 直接用目录里的 dist 构建，不需要 node，几秒完成
#
# 构建：
#   docker build -t letmedoit-admin:latest .
#   docker build --build-arg BASE_IMAGE=<本地已有镜像> -t letmedoit-admin:latest .
#
# 拉不到 docker.io 时（树莓派/内网常见）：
#   1) 先看本机有没有现成的：docker images | grep -i nginx
#      有就用 --build-arg BASE_IMAGE=nginx:xxx 复用
#   2) 或者配镜像加速器后重试，详见 README 里的「拉不到基础镜像」

ARG BASE_IMAGE=nginx:1.27-alpine
FROM ${BASE_IMAGE}

ENV TZ=Asia/Shanghai

# 时区：让 nginx 日志是北京时间；apk 源不可达时降级 UTC，不阻断构建
RUN { apk add --no-cache tzdata \
      && cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
      && echo "${TZ}" > /etc/timezone; } \
    || echo "WARN: tzdata 安装失败，容器内时间仍为 UTC"

# 覆盖默认站点配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 前端静态文件
COPY dist/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

STOPSIGNAL SIGQUIT
