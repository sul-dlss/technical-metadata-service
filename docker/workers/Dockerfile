# This Dockerfile is optimized for running in development. That means it trades
# build speed for size. If we were using this for production, we might instead
# optimize for a smaller size at the cost of a slower build.
#
# NOTE: This uses a Debian-based image rather than an Alpine-based image so that
#       we can install Debian packages. In particular: siegfried.
FROM ruby:2.7.0-buster

# postgresql-client is required for invoke.sh
RUN curl -sS https://bintray.com/user/downloadSubjectPublicKey?username=bintray | apt-key add - && \
  echo "deb http://dl.bintray.com/siegfried/debian wheezy main" | tee -a /etc/apt/sources.list && \
  apt-get update -qq && \
  apt-get install -y build-essential postgresql-client siegfried

# Get bundler 2.0
RUN gem install bundler

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'production'
RUN bundle install

COPY . .

CMD ["./docker/workers/invoke.sh"]
