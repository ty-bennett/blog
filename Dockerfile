# Dockerfile - Jekyll + Node (UTF-8 + Bundler auto-detect)
FROM ruby:4.0-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
WORKDIR /app

# Install system dependencies, locales, git, and Node 18 (includes npm)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       ca-certificates curl gnupg build-essential git locales \
  && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen en_US.UTF-8 \
  && update-locale LANG=en_US.UTF-8 \
  && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# Copy gem manifests and any gemspec so `gemspec` entries work during bundle install
COPY Gemfile Gemfile.lock *.gemspec ./

# Detect Bundler from Gemfile.lock and install it, then bundle install
RUN BUNDLER_VER="$(awk '/^BUNDLED WITH$/ { getline; print $1; exit }' Gemfile.lock || true)" \
  && if [ -n "$BUNDLER_VER" ]; then \
       echo "Installing bundler $BUNDLER_VER" && gem install bundler -v "$BUNDLER_VER"; \
     else \
       echo "No bundler pinned in Gemfile.lock, installing latest bundler" && gem install bundler; \
     fi \
  && if [ -n "$BUNDLER_VER" ]; then \
       bundle _${BUNDLER_VER}_ config set --local path 'vendor/bundle' || true; \
       bundle _${BUNDLER_VER}_ install --jobs 4 --retry 3; \
     else \
       bundle config set --local path 'vendor/bundle' || true; \
       bundle install --jobs 4 --retry 3; \
     fi

# Install node deps (cache package.json)
COPY package.json package-lock.json* ./
RUN if [ -f package.json ]; then npm ci --no-audit --no-fund; fi

# Copy the rest of the site
COPY . .

# Build frontend assets (if you have a build script)
RUN if npm run | grep -q "build"; then npm run build; fi

EXPOSE 4000

# Default dev command (serve with livereload if configured)
CMD ["bundle", "exec", "jekyll", "serve"]

