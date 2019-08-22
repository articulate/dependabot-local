FROM ruby:2.6.3-stretch

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update -qq \
    && apt-get remove cmdtest yarn \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g yarn

WORKDIR /opt

COPY Gemfile .

RUN bundle install

ENV DEPENDABOT_NATIVE_HELPERS_PATH="/opt/native-helpers"

RUN mkdir -p $DEPENDABOT_NATIVE_HELPERS_PATH/npm_and_yarn

ENV MIX_HOME="$DEPENDABOT_NATIVE_HELPERS_PATH/hex/mix"

RUN cp -r $(bundle show dependabot-npm_and_yarn)/helpers $DEPENDABOT_NATIVE_HELPERS_PATH/npm_and_yarn/helpers

RUN $DEPENDABOT_NATIVE_HELPERS_PATH/npm_and_yarn/helpers/build $DEPENDABOT_NATIVE_HELPERS_PATH/npm_and_yarn

COPY update.rb Gemfile Gemfile.lock ./
COPY lib ./lib
