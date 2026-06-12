FROM node:22-alpine AS builder

RUN apk add --no-cache curl unzip \
    && npm install -g pnpm tsup

WORKDIR /build

ARG VERSION=1.11.4

RUN curl --retry 5 -f -L https://github.com/libnoname/noname/archive/refs/tags/v${VERSION}.zip -o /tmp/source.zip \
    && unzip /tmp/source.zip -d /build \
    && rm -rf /tmp/source.zip

WORKDIR /build/noname-${VERSION}

RUN sed -i '/start http:\/\/localhost/d' ./packages/fs/src/index.ts \
    && sed -i "s/app.listen({ port: cfg.port }, callback);/app.listen({ port: cfg.port, host: '0.0.0.0' }, callback);/g" ./packages/fs/src/index.ts

RUN pnpm install \
    && pnpm run build \
    && pnpm -F @noname/server exec tsup


# ==========================================
# 阶段二：RUNNER (干净的生产运行环境)
# ==========================================
FROM node:22-alpine AS runner

ARG VERSION=1.11.4

WORKDIR /noname

COPY --from=builder /build/noname-${VERSION}/package.json ./package.json
COPY --from=builder /build/noname-${VERSION}/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /build/noname-${VERSION}/pnpm-workspace.yaml ./pnpm-workspace.yaml

COPY --from=builder /build/noname-${VERSION}/apps/core/package.json ./apps/core/package.json
COPY --from=builder /build/noname-${VERSION}/apps/core/pnpm-lock.yaml ./apps/core/pnpm-lock.yaml
COPY --from=builder /build/noname-${VERSION}/packages/fs/package.json ./packages/fs/package.json
COPY --from=builder /build/noname-${VERSION}/packages/fs/pnpm-lock.yaml ./packages/fs/pnpm-lock.yaml
COPY --from=builder /build/noname-${VERSION}/packages/jit/package.json ./packages/jit/package.json
COPY --from=builder /build/noname-${VERSION}/packages/jit/pnpm-lock.yaml ./packages/jit/pnpm-lock.yaml
COPY --from=builder /build/noname-${VERSION}/packages/server/package.json ./packages/server/package.json
COPY --from=builder /build/noname-${VERSION}/packages/server/pnpm-lock.yaml ./packages/server/pnpm-lock.yaml

# 复制编译产物
COPY --from=builder /build/noname-${VERSION}/dist ./app
COPY --from=builder /build/noname-${VERSION}/packages/fs/dist ./packages/fs/dist
COPY --from=builder /build/noname-${VERSION}/packages/jit/dist ./packages/jit/dist
COPY --from=builder /build/noname-${VERSION}/packages/server/dist ./packages/server/dist

RUN npm install -g pnpm \
    && pnpm -F noname...  install --prod \
    && pnpm -F @noname/server install --prod \
    && npm uninstall -g pnpm \
    && rm -rf /root/.npm /root/.local /root/.pnpm-store

EXPOSE 8089
EXPOSE 8082

# 复制启动脚本并赋予执行权限
COPY ./start.sh /root/start.sh
RUN chmod +x /root/start.sh

# 容器启动命令：执行启动脚本
CMD ["/bin/sh", "/root/start.sh"]