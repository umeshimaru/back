# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION=3.4.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# 作業ディレクトリ設定
WORKDIR /rails

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 環境変数設定（本番環境用）
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY ./spe-con/Gemfile ./spe-con/Gemfile.lock ./
RUN bundle config --global frozen false && bundle install && bundle config --global frozen true
RUN bundle exec bootsnap precompile app/ lib/ && \
    rm -rf /usr/local/bundle/ruby/*/cache || true && \
    rm -rf /usr/local/bundle/ruby/*/bundler/gems/*/.git || true
# Copy application code
COPY ./spe-con ./rails

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
# 必要なディレクトリを作成し権限を設定
RUN mkdir -p db log storage tmp && \
    groupadd --system --gid 1000 rails || true && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash || true && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
