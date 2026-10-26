#!/usr/bin/env bash
#
# 本地启动 sa-app（读取 .env 注入环境变量）
#
# 为什么需要这个脚本：配置文件里不允许出现明文凭证（DB 密码、AppSecret、COS 密钥），
# 本地开发把真实值放在 .env（已 gitignore），启动时注入。
#
# 用法：
#   ./run-local.sh                  # 默认 1025 端口、mock 关闭
#   ./run-local.sh --wx.miniapp.mock=true   # 跑 e2e 时用 mock 登录
#
set -e
cd "$(dirname "$0")"

ENV_FILE=.env
if [ ! -f "$ENV_FILE" ]; then
  echo "缺少 $ENV_FILE，请先复制 .env.example 填好本地凭证" >&2
  exit 1
fi

JAR=sa-app/target/sa-app-dev-3.0.0.jar
if [ ! -f "$JAR" ]; then
  echo "缺少 $JAR，请先编译：mvn -o -pl sa-app -am package -DskipTests -Pdev" >&2
  exit 1
fi

# set -a 让 source 进来的变量自动 export 给 java 进程
set -a
# shellcheck disable=SC1090
. "./$ENV_FILE"
set +a

exec java -jar "$JAR" --server.port=1025 "$@"
