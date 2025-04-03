# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

# 作業ディレクトリ設定
WORKDIR /rails

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    nodejs \
    yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# 本番環境用の環境変数設定
ENV RAILS_ENV="production" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# GemfileとGemfile.lockをコピーして依存関係をインストール
COPY spe-con/Gemfile spe-con/Gemfile.lock ./
RUN bundle install && rm -rf "${BUNDLE_PATH}"/ruby/*/cache || exit 1

# アプリケーションコードをコピー
COPY spe-con/ ./

# Bootsnapによるコード最適化（エラー時停止）
RUN bundle exec bootsnap precompile app/ lib/ || exit 1

# アセットのプリコンパイル（ダミーキーで実行、エラー時停止）
RUN SECRET_KEY_BASE=dummy_key ./bin/rails assets:precompile || exit 1

# 非rootユーザーで実行するための設定
RUN groupadd --system --gid 1000 rails && useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && mkdir -p db log storage tmp && chown -R rails:rails db log storage tmp

USER rails

# Entrypointでデータベース準備を実行
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/thrust", "./bin/rails", "server"]
