#Node.js & Yarn
FROM node:15.14-alpine as node

RUN apk add --no-cache bash curl && \
    curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.22.5

#Ruby & Bundler & mysql-client
FROM ruby:3.0.1-alpine

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /opt/yarn-* /opt/yarn
RUN ln -fs /opt/yarn/bin/yarn /usr/local/bin/yarn

RUN apk update && apk upgrade \
  && apk add --no-cache build-base \
  libxml2-dev libxslt-dev \
  mysql-client mysql-dev \
  nodejs yarn \
  git bash less

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apk del tzdata

ENV APP_ROOT /app
RUN mkdir $APP_ROOT
WORKDIR $APP_ROOT

ENV LANG=ja_JP.UTF-8

ADD ./backend/Gemfile $APP_ROOT/Gemfile
ADD ./backend/Gemfile.lock $APP_ROOT/Gemfile.lock

RUN bundle install
COPY ./backend /app
