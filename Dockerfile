# Written by Ty Bennett

# Ruby >= 3.3 is required: html-proofer -> async -> console needs it.
FROM ruby:3.4-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

# Install system dependencies, locales, git, and Node 22 (includes npm)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg build-essential git locales \
  && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen en_US.UTF-8 \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# Gem manifests. The gemspec's `git ls-files` needs git on PATH (installed above);
# it resolves to an empty file list here, which bundler is fine with.
COPY Gemfile Gemfile.lock* *.gemspec ./

RUN gem install bundler \
  && bundle config set --local path 'vendor/bundle' \
  && bundle install --jobs 4 --retry 3

# Install node deps
COPY package.json package-lock.json* ./

RUN npm ci --no-audit --no-fund

# Copy rest of the website (see .dockerignore — it keeps the host's
# node_modules/ and vendor/ from clobbering what we just installed)
COPY . .

# Build front end assets
RUN npm run build

EXPOSE 4000

# Bind to 0.0.0.0 so the port is reachable from outside the container
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000"]
