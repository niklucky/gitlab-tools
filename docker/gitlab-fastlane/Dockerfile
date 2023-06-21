FROM reactnativecommunity/react-native-android

RUN apt update
RUN apt-get install --no-install-recommends -y --allow-unauthenticated build-essential git ruby-full
RUN gem install rake && \
  gem install fastlane && \
  gem install bundler

COPY ./Gemfile ./Gemfile
RUN bundle update

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8