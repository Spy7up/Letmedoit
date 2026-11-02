#!/usr/bin/env bash
###############################################################################
# 【服务器执行】用当前目录的 dist 构建镜像，并替换现有容器
#
# 目录要求（都在同一目录）：
#   dist/        前端产物（本地 npm run build:prod 生成后上传）
#   Dockerfile
#   nginx.conf
#   deploy.sh
#
# 用法：
#   ./deploy.sh                                  # 端口 9090，后端用 nginx.conf 里的地址
#   ./deploy.sh -p 8080                          # 改宿主机端口
#   ./deploy.sh -b http://10.0.0.5:8082          # 改后端地址（就地修改 nginx.conf）
#   ./deploy.sh -B nginx:stable-alpine           # 用本机已有的 nginx 镜像当底座（拉不到 docker.io 时）
#   ./deploy.sh -n my-admin -i my-image          # 改容器名 / 镜像名
#
# 流程：docker build → 删旧容器 → 起新容器 → 健康探测
###############################################################################

set -euo pipefail

# 先记下脚本绝对路径（cd 之后相对路径会失效，-h 要读自身的头部注释）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
cd "$SCRIPT_DIR"

IMAGE=${IMAGE:-letmedoit-admin}
CONTAINER=${CONTAINER:-letmedoit-admin}
PORT=${PORT:-9090}
BACKEND=""
BASE_IMAGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--port)       PORT=$2; shift 2 ;;
    -n|--name)       CONTAINER=$2; shift 2 ;;
    -i|--image)      IMAGE=$2; shift 2 ;;
    -b|--backend)    BACKEND=$2; shift 2 ;;
    -B|--base-image) BASE_IMAGE=$2; shift 2 ;;
    -h|--help)       sed -n '3,18p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)               echo "未知参数: $1（-h 查看用法）" >&2; exit 1 ;;
  esac
done

# ---------------- 前置检查 ----------------
command -v docker >/dev/null 2>&1 || { echo "!! 未安装 docker" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "!! docker 未启动或当前用户无权限" >&2; exit 1; }

for f in Dockerfile nginx.conf dist/index.html; do
  [ -e "$f" ] || { echo "!! 缺少 $f（dist 请整个目录上传，不要只传里面的文件）" >&2; exit 1; }
done

# ---------------- 后端地址 ----------------
if [ -n "$BACKEND" ]; then
  BACKEND=${BACKEND%/}
  [ -f nginx.conf.bak ] || cp nginx.conf nginx.conf.bak
  sed -i -E "s|proxy_pass http://[^/ ]+/;|proxy_pass ${BACKEND}/;|" nginx.conf
  echo "==> 后端地址已改为 ${BACKEND}（原文件备份在 nginx.conf.bak）"
fi
echo "    后端: $(grep -o 'proxy_pass [^;]*;' nginx.conf | head -1)"

# ---------------- 构建镜像 ----------------
TAG=$(date +%Y%m%d-%H%M%S)
if [ -n "$BASE_IMAGE" ]; then
  echo "==> 构建镜像 ${IMAGE}:${TAG}（底座: ${BASE_IMAGE}）"
else
  echo "==> 构建镜像 ${IMAGE}:${TAG}"
fi

build_failed=0
if [ -n "$BASE_IMAGE" ]; then
  docker build --build-arg "BASE_IMAGE=${BASE_IMAGE}" -t "${IMAGE}:${TAG}" -t "${IMAGE}:latest" . || build_failed=1
else
  docker build -t "${IMAGE}:${TAG}" -t "${IMAGE}:latest" . || build_failed=1
fi

if [ "$build_failed" != "0" ]; then
  cat >&2 <<'EOF'

!! 构建失败。如果是拉基础镜像超时（context deadline exceeded）：
   1) 看本机有没有现成的 nginx 镜像
        docker images | grep -i nginx
      有就直接复用（不用联网）
        ./deploy.sh -B <仓库名:tag>
   2) 没有则配镜像加速器后重启 docker 再试
        sudo tee /etc/docker/daemon.json <<'JSON'
        { "registry-mirrors": ["https://docker.m.daocloud.io", "https://docker.1panel.live"] }
        JSON
        sudo systemctl daemon-reload && sudo systemctl restart docker
EOF
  exit 1
fi

# ---------------- 替换容器 ----------------
OLD_IMAGE=""
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  OLD_IMAGE=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER" 2>/dev/null || echo "")
  echo "==> 移除旧容器 $CONTAINER（旧镜像: ${OLD_IMAGE:-未知}）"
  docker rm -f "$CONTAINER" >/dev/null
fi

echo "==> 启动新容器（宿主 ${PORT} -> 容器 80）"
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p "${PORT}:80" \
  -e TZ=Asia/Shanghai \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  "${IMAGE}:${TAG}" >/dev/null

# ---------------- 等健康检查 ----------------
st=starting
for _ in $(seq 1 30); do
  st=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER" 2>/dev/null || echo unknown)
  [ "$st" = "healthy" ] && break
  if [ "$st" = "unhealthy" ]; then
    docker logs --tail 50 "$CONTAINER" || true
    echo "!! 容器健康检查失败" >&2
    exit 1
  fi
  sleep 2
done
echo "    容器状态: $st"

# ---------------- 探测 ----------------
probe() {
  local url=$1 code
  if command -v curl >/dev/null 2>&1; then
    code=$(curl -s -o /dev/null -m 5 --noproxy '*' -w '%{http_code}' "$url" 2>/dev/null || true)
  else
    code=$(wget -q -S -O /dev/null -T 5 "$url" 2>&1 | awk '/HTTP\//{print $2; exit}' || true)
  fi
  printf '%s' "${code:-000}"
}

page=$(probe "http://127.0.0.1:${PORT}/")
api=$(probe "http://127.0.0.1:${PORT}/admin-api/login/getCaptcha")
if [ "$page" = "200" ]; then
  echo "    首页: HTTP 200 OK"
else
  echo "    首页: HTTP $page  !! 检查日志: docker logs --tail 50 $CONTAINER"
fi
case "$api" in
  200|401|403) echo "    接口: HTTP $api（代理正常）" ;;
  404)         echo "    接口: HTTP 404（后端 context-path 不是 / ，改 nginx.conf 的 proxy_pass 前缀）" ;;
  *)           echo "    接口: HTTP $api  !! 容器可能连不到后端，见 nginx.conf 的 proxy_pass" ;;
esac

# ---------------- 汇总 ----------------
IP=$(hostname -I 2>/dev/null | awk '{print $1}') || IP=""
echo ""
echo "部署完成"
echo "  访问地址: http://${IP:-<服务器IP>}:${PORT}/"
echo "  镜像    : ${IMAGE}:${TAG}（同时打了 :latest）"
if [ -n "$OLD_IMAGE" ]; then
  echo "  回滚    : docker rm -f $CONTAINER && docker run -d --name $CONTAINER --restart unless-stopped -p ${PORT}:80 $OLD_IMAGE"
  echo "  清旧镜像: docker image prune -f"
fi
