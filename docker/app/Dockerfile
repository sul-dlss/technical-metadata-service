FROM ruby:3.4.1-bookworm

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        postgresql-client postgresql-contrib libpq-dev

# Get latest bundler
RUN gem install bundler

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'production' && \
  bundle install

COPY . .

CMD ["./docker/app/invoke.sh"]
