# 构建阶段
FROM --platform=$BUILDPLATFORM rust:1.83.0-slim-bookworm as builder
WORKDIR /app

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    protobuf-compiler \
    pkg-config \
    libssl-dev \
    nodejs \
    npm \
    gcc-x86-64-linux-gnu \
    libc6-dev-amd64-cross \
    && rm -rf /var/lib/apt/lists/*

# 设置交叉编译环境变量
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc \
    CC_x86_64_unknown_linux_gnu=x86_64-linux-gnu-gcc \
    CXX_x86_64_unknown_linux_gnu=x86_64-linux-gnu-g++ \
    PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig" \
    PKG_CONFIG_ALLOW_CROSS=1

# 复制项目文件
COPY . .

# 构建
RUN rustup target add x86_64-unknown-linux-gnu && \
    cargo build --target x86_64-unknown-linux-gnu --release && \
    cp target/x86_64-unknown-linux-gnu/release/cursor-api /app/cursor-api

# 运行阶段
FROM debian:bookworm-slim
WORKDIR /app
ENV TZ=Asia/Shanghai

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# 复制构建产物
COPY --from=builder /app/cursor-api .

# 设置默认端口
ENV PORT=3000

# 动态暴露端口
EXPOSE ${PORT}

CMD ["./cursor-api"]
