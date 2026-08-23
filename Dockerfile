# Written by Ty Bennett

FROM ruby:3.4-slim

WORKDIR /app

# Install system dependencies, locales, git, and Node 22 (includes npm)
RUN apt-get update && apt-get install -y ca-certificates curl gnupg build-essential git locales \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs

# Copy gem deps
COPY Gemfile Gemfile.lock* *.gemspec ./

# Install ruby deps
RUN gem install bundler && bundle install

# Install node deps
COPY package.json package-lock.json* ./

RUN npm ci

COPY . .

# Build front end assets
RUN npm run build

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
