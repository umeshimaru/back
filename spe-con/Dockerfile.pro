# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

# Railsアプリケーションの作業ディレクトリ
WORKDIR /rails

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    libpq-dev \
    nodejs \
    yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# 本番環境用の環境変数を設定
ENV RAILS_ENV="production" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# マルチステージビルド：ビルドステージ
FROM base AS build

# 必要なビルドツールをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Bundlerバージョンを指定してインストール
RUN gem install bundler -v '2.6.2'

# GemfileとGemfile.lockをコピーして依存関係をインストール
COPY ./spe-con/Gemfile ./spe-con/Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git || exit 1

# アプリケーションコードをコピー
COPY . .

# Bootsnapによるコード最適化（エラー時に停止）
RUN bundle exec bootsnap precompile app/ lib/ || exit 1

# アセットのプリコンパイル（ダミーキーで実行、エラー時に停止）
RUN SECRET_KEY_BASE=dummy_key ./bin/rails assets:precompile || exit 1

# 最終ステージ：実行環境用イメージ
FROM base

# ビルド成果物（Gemやアプリケーションコード）をコピー
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# 非rootユーザーで実行するための設定
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER rails

# Entrypointでデータベース準備を実行
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# ヘルスチェック設定
HEALTHCHECK --interval=15s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

EXPOSE 3000

CMD ["./bin/thrust", "./bin/rails", "server"]
