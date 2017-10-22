FROM ruby:2.4.0-slim

MAINTAINER High Fidelity <contact@highfidelity.io>

RUN mkdir -p /gem/lib/fake_braintree
WORKDIR /gem

RUN apt-get update && \
    apt-get install -y git \
                       build-essential \
                       qt5-default \
                       libqt5webkit5-dev \
                       xvfb

COPY Gemfile /gem
COPY *.gemspec /gem
COPY lib/fake_braintree/version.rb /gem/lib/fake_braintree

RUN bundle install

COPY . /gem

ENTRYPOINT ["bundle", "exec"]
CMD ["rake", "-T"]
