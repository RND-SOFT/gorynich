ARG BUILD_TAG=2.6
  
FROM gemtestbase:${BUILD_TAG} as image

RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc \
  && echo 'gem: --no-document' > ~/.gemrc

WORKDIR /home/app

ARG GEM_STORAGE_AUTH

ENV BUNDLE_NEXUS__RNDS__LOCAL ${GEM_STORAGE_AUTH}

ADD Gemfile Gemfile.lock *.gemspec /home/app/
ADD lib/gorynich/version.rb /home/app/lib/gorynich/
ADD spec/dummy/config/database.yml /home/app/spec/dummy/config/database.yml

RUN set -ex \
  && apk add --no-cache ca-certificates curl \
  && curl -k https://rnds.pro/bundle_ca.crt --output /usr/local/share/ca-certificates/bundle_ca.crt \
  && cat /usr/local/share/ca-certificates/bundle_ca.crt >> /etc/ssl/certs/ca-certificates.crt \
  && echo ${BUILD_TAG}; echo $BUILD_TAG; echo $(ruby -v); echo $RUBY_VERSION \
  && cp /etc/ssl/certs/ca-certificates.crt /usr/local/lib/ruby/${BUILD_TAG}/rubygems/ssl_certs/rubygems.org/ca-certificates.pem \
  && update-ca-certificates

RUN set -ex \
  && gem source --add https://${GEM_STORAGE_AUTH}@library.rnds.pro/repository/internal/ \
  && gem install bundler && gem update bundler \
  && bundle install --jobs=3 --full-index \
  && rm -rf /tmp/* /var/tmp/* /usr/src/ruby /root/.gem /usr/local/bundle/cache

ADD . /home/app/

RUN set -ex \
  && bundle install --jobs=3 --full-index \
  && rm -rf /tmp/* /var/tmp/* /usr/src/ruby /root/.gem /usr/local/bundle/cache

CMD ["tail", "-f", "/dev/null"]
