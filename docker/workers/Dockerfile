# NOTE: This uses a Debian-based image rather than an Alpine-based image so that
#       we can install Debian packages. In particular: siegfried.
FROM ruby:3.3.2-bookworm

# Two-pass package update: first install everything except siegfried, which is
# installed via add-apt-repository, a tool that isn't installed until
# software-properties-common is installed.
#
# * postgresql-client is required for invoke.sh
# * siegfried, exiftool, poppler, and mediainfo are needed for file characterization
RUN apt-get update -qq && \
    apt-get install -y build-essential postgresql-client exiftool poppler-utils mediainfo software-properties-common

RUN curl -sL "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x20F802FE798E6857" | gpg --dearmor | tee /usr/share/keyrings/siegfried-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/siegfried-archive-keyring.gpg] https://www.itforarchivists.com/ buster main" | tee -a /etc/apt/sources.list.d/siegfried.list
RUN apt-get update && apt-get install siegfried

# Get latest bundler
RUN gem install bundler

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'production'
RUN bundle install

COPY . .

CMD ["./docker/workers/invoke.sh"]
