### 无名杀官方仓库[libnoname/noname](https://github.com/libnoname/noname) 


---

# 🚀 无名杀 Docker 镜像使用指南

本镜像对无名杀（Noname）进行了服务端编译与工程化容器包装 。容器内集成了**前端游戏本体**、**本地文件系统服务 (`@noname/fs`)** 以及 **Websocket 联机服务 (`@noname/server`)** 。

## ⚙️ 端口说明

容器共对外暴露了两个核心端口 ：

* 
**`8089`**：游戏本体网页 + 文件系统服务。


* 
**`8082`**：联机 Websocket 独立服务 。



---

## 🛠️ 部署与运行命令

### 1. 基础启动命令

如果你只需要最基础的容器化运行，不考虑更新游戏素材或持久化存档，直接运行：

```bash
docker run -d \
  --name <容器名称或ID> \
  -p 8089:8089 \
  -p 8082:8082 \
  --restart unless-stopped \
  ghcr.io/oculr/noname-docker:latest
```

> 💡 **使用方法**：启动后，在浏览器（电脑/手机均可）输入 `http://<容器IP>:8089` 即可直接开始游戏！

---

### 2. 高级启动命令（数据持久化 + 强烈推荐）

无名杀是一款频繁更新、且允许玩家自定义皮肤、扩展和武将的游戏。如果容器被销毁，你的存档和自定义内容将会丢失。
为了实现**数据持久化**，我们需要把容器内的资源目录 `/noname/app` 挂载出来 。

#### 第一步：准备宿主机目录
在宿主机上创建你想存放无名杀游戏本体数据的目录（以 `/opt/noname/data` 为例，你可以根据需要修改）：
```bash
mkdir -p /opt/noname/data
```

#### 第二步：编写配置文件

在服务器任意目录下创建 `docker-compose.yml` 文件，并将下面的内容粘贴进去：

```yaml
version: '3.8'

services:
  noname-game:
    image: ghcr.io/oculr/noname-docker:latest
    container_name: noname-game
    ports:
      - 8089:8089
      - 8082:8082
    volumes:
      - noname_data:/noname/app
    restart: unless-stopped

volumes:
  noname_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/noname/data  # 🌟 填入你刚才创建的宿主机绝对路径

```

### 第三步：一键启动游戏

在 `docker-compose.yml` 所在的目录下执行以下命令：

```bash
docker compose up -d

```

---

## 👥 局域网联机配置

1. 在游戏内选择`选项` -> `开始` -> `联机”`
2. 输入联机地址`ws://<容器IP>:8082`

---

## 🔄 跟随官方 Release 自动更新
```bash
# 拉取最新镜像
docker pull ghcr.io/oculr/noname-docker:latest

# 停止并删除旧容器
docker stop <容器名称或ID>
docker rm <容器名称或ID>

# 重新执行上方的 docker run 挂载启动命令即可完成无缝升级！
```
