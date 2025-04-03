# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

# 作業ディレクトリ設定
WORKDIR /rails

# 必要なパッケージをインストール
RUN apt-get update -qq && \	RUN apt-get update -qq && \
apt-get install --no-install-recommends -y curl libjemalloc2 libvips libyaml-dev nodejs yarn && \	apt-get install --no-install-recommends -y curl libjemalloc2 libvips && \
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# 環境変数設定（本番環境用）
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Throw-away build stage to reduce size of final image
FROM base AS build

# 必要なビルドツールをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

RUN gem install bundler -v '2.6.2'

# GemfileとGemfile.lockをコピーして依存関係をインストール
COPY ./spe-con/Gemfile ./spe-con/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# アプリケーションコードをコピー
COPY ./spe-con ./

# Bootsnapによるコード最適化
RUN bundle exec bootsnap precompile app/ lib/

# アセットのプリコンパイル（ダミーキーで実行）
RUN SECRET_KEY_BASE=dummy_key ./bin/rails assets:precompile

# Final stage for app image
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

# サーバー起動コマンド（デフォルトはThruster経由）
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
