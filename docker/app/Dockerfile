# This Dockerfile is optimized for running in development. That means it trades
# build speed for size. If we were using this for production, we might instead
# optimize for a smaller size at the cost of a slower build.
FROM ruby:3.0.3-alpine

# postgresql-client is required for invoke.sh
RUN apk add --update --no-cache  \
  build-base \
  postgresql-dev \
  postgresql-client \
  tzdata \
  yarn

# Get latest bundler
RUN gem install bundler

WORKDIR /app

COPY Gemfile Gemfile.lock package.json yarn.lock ./

RUN bundle config set without 'production' && \
  bundle install && \
  yarn install

COPY . .

CMD ["./docker/app/invoke.sh"]
