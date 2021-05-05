FROM ruby:2.7.3-alpine

ENV PORT 8080
EXPOSE 8080
WORKDIR /app

RUN apk --no-cache add \
      build-base \
      chromium \
      chromium-chromedriver \
      dumb-init \
      git \
      nodejs \
      postgresql-dev \
      bash # debugging and datadog events

# Set up deploy user, working directory and shared folders for Puma / Nginx
RUN mkdir /shared && \
    mkdir /shared/config && \
    mkdir /shared/pids && \
    mkdir /shared/sockets

COPY .ruby-version Gemfile* ./

RUN gem install bundler && \
    bundle install --frozen --jobs $(nproc)

COPY . ./
RUN adduser -D deploy && \
    chown -R deploy:deploy /app && \
    chown -R deploy:deploy /shared

USER deploy

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bundle", "exec", "puma", "-C", "config/puma.config"]
