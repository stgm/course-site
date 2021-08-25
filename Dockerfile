FROM ruby:2.7.4-bullseye

RUN apt-get update && apt-get -y install libcurl4-openssl-dev
RUN curl -sSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

ENV RAILS_ENV=production

RUN mkdir /app
WORKDIR /app

RUN gem install bundler:1.17.2

COPY Gemfile* /app

RUN bundle install

COPY . ./

RUN SECRET_KEY_BASE=dummyvalue bundle exec rake assets:precompile

ENV RAILS_SERVE_STATIC_FILES=true

ENTRYPOINT [ "/app/init.sh" ]