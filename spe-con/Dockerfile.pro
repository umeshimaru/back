
# # ベースイメージ
# ARG RUBY_VERSION=3.4.1
# FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# # 作業ディレクトリ設定
# WORKDIR /rails

# # 必要なパッケージをインストール
# RUN apt-get update -qq && \
#     apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client build-essential git libpq-dev pkg-config && \
#     rm -rf /var/lib/apt/lists /var/cache/apt/archives

# # 環境変数設定（本番環境用）
# ENV RAILS_ENV="production" \
#     BUNDLE_DEPLOYMENT="1" \
#     BUNDLE_PATH="/usr/local/bundle" \
#     BUNDLE_WITHOUT="development"

# # Throw-away build stage to reduce size of final image
# FROM base AS build

# # Install packages needed to build gems
# RUN apt-get update -qq && \
#     apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
#     rm -rf /var/lib/apt/lists /var/cache/apt/archives

# # Install application gems
# COPY ./spe-con/Gemfile ./spe-con/Gemfile.lock ./
# RUN bundle config --global frozen false && bundle install && bundle config --global frozen true
# RUN bundle exec bootsnap precompile app/ lib/ && \
#     rm -rf /usr/local/bundle/ruby/*/cache || true && \
#     rm -rf /usr/local/bundle/ruby/*/bundler/gems/*/.git || true
# # Copy application code
# COPY ./spe-con ./rails

# # Precompile bootsnap code for faster boot times
# RUN bundle exec bootsnap precompile app/ lib/

# # Final stage for app image
# FROM base

# # Copy built artifacts: gems, application
# COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
# COPY --from=build /rails /rails

# # Run and own only the runtime files as a non-root user for security
# # 必要なディレクトリを作成し権限を設定
# RUN mkdir -p db log storage tmp && \
#     groupadd --system --gid 1000 rails || true && \
#     useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash || true && \
#     chown -R rails:rails db log storage tmp

# USER 1000:1000

# # Entrypoint prepares the database.
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# # Start server via Thruster by default, this can be overwritten at runtime
# EXPOSE 80
# CMD ["./bin/thrust", "./bin/rails", "server"]


# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t rails8_on_docker .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name rails8_on_docker rails8_on_docker

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version

# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

# 作業ディレクトリ設定
WORKDIR /rails

# 必要なパッケージのみインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 環境変数設定（本番環境用）
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

# ビルド用ステージ
FROM base AS build

# ビルド用パッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# GemfileとGemfile.lockをコピーして依存関係をインストール
COPY ./spe-con/Gemfile ./spe-con/Gemfile.lock ./
RUN bundle install

# アプリケーションコード全体をコピー
COPY . .

# アセットプリコンパイル
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# 最終ステージ（本番用イメージ）
FROM base

# ビルド成果物をコピー
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# 必要なディレクトリ作成と権限設定
RUN mkdir -p tmp log storage && \
    chown -R nobody:nogroup tmp log storage

USER nobody:nogroup

# Entrypointスクリプト（PIDファイル削除など）
ENTRYPOINT ["bash", "-c", "rm -f tmp/pids/server.pid && exec \"$@\"", "--"]

# サーバーポート公開
EXPOSE 3000

# サーバー起動コマンド
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
