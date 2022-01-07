# This Dockerfile is optimized for running in development. That means it trades
# build speed for size. If we were using this for production, we might instead
# optimize for a smaller size at the cost of a slower build.
#
# NOTE: This uses a Debian-based image rather than an Alpine-based image so that
#       we can install Debian packages. In particular: siegfried.
FROM ruby:3.0.3-buster


# Two-pass package update: first install everything except siegfried, which is
# installed via add-apt-repository, a tool that isn't installed until
# software-properties-common is installed.
#
# * postgresql-client is required for invoke.sh
# * siegfried, exiftool, poppler, and mediainfo are needed for file characterization
RUN apt-get update -qq && \
    apt-get install -y build-essential postgresql-client exiftool poppler-utils mediainfo software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 20F802FE798E6857 && \
    add-apt-repository "deb https://www.itforarchivists.com/ buster main" && \
    apt-get update -qq && \
    apt-get install -y siegfried

# Get latest bundler
RUN gem install bundler

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'production'
RUN bundle install

COPY . .

CMD ["./docker/workers/invoke.sh"]
