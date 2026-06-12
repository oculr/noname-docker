#!/bin/sh

# 1. 启动文件系统服务（后台运行），并将游戏本体目录指向 /app
echo "Starting @noname/fs..."
node /noname/packages/fs/dist/entry.cjs --dirname=/noname/app &

# 2. 启动 Websocket 联机服务（前台运行，夯住容器主进程）
echo "Starting @noname/server..."
node /noname/packages/server/dist/index.cjs