FROM ruby:2.3-stretch
WORKDIR /var/www
COPY Gemfile .
RUN bundle
