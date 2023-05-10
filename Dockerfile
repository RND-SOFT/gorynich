ARG BASE_TAG=alpine
ARG BASE_IMG=library/ruby
ARG BUILDKIT_INLINE_CACHE=1

FROM ${BASE_IMG}:${BASE_TAG}

WORKDIR /home/app

RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc \
  && echo 'gem: --no-document' > ~/.gemrc

RUN set -ex \
  && apk add --no-cache git curl tzdata build-base postgresql-dev postgresql-client libstdc++ libxml2 docker docker-compose

ADD Gemfile Gemfile.lock *.gemspec /home/app/
ADD lib/gorynich/version.rb /home/app/lib/gorynich/
ADD spec/dummy/config/database.yml /home/app/spec/dummy/config/database.yml

ARG GEM_STORAGE_AUTH

ENV BUNDLE_NEXUS__RNDS__LOCAL ${GEM_STORAGE_AUTH}

RUN set -ex \
  && gem install bundler && gem update bundler \
  && bundle install --jobs=3 \
  && gem cleanup  \
  && rm -rf /tmp/* /var/tmp/* /usr/src/ruby /root/.gem /usr/local/bundle/cache

ONBUILD ADD . /home/app/

ONBUILD RUN set -ex \
  && bundle install --jobs=3 \
  && rm -rf /tmp/* /var/tmp/* /usr/src/ruby /root/.gem /usr/local/bundle/cache

CMD ["tail", "-f", "/dev/null"]


