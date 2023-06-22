FROM reactnativecommunity/react-native-android

RUN apt update
RUN apt-get install --no-install-recommends -y --allow-unauthenticated \
    build-essential \
    git \
    ruby-full \
    curl \
    python3 \
    python3-dev

RUN gem install rake && \
  gem install fastlane && \
  gem install bundler

COPY ./docker/gitlab-fastlane-android/Gemfile ./Gemfile
RUN bundle update

COPY ./docker/gitlab-fastlane-android/Fastfile /tmp/Fastfile
COPY ./lib/notify_telegram.py /usr/local/bin/notify_telegram.py