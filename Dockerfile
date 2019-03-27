FROM heroku/heroku:18-build

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq \
 && apt-get install -qq -y daemontools ffmpeg \
 && apt-get -qq -y \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    dist-upgrade

RUN apt-get update -qq && apt-get install -y curl git build-essential \
    ffmpeg libpq-dev imagemagick \
    libfftw3-dev libmagickwand-dev libopenexr-dev liborc-0.4-0 \
    gobject-introspection libgsf-1-dev \
    libglib2.0-dev liborc-0.4-dev automake libtool swig gtk-doc-tools

RUN apt-get clean \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/tmp/*

# Build libvips from source (last resort because takes forever)
RUN git clone https://github.com/jcupitt/libvips.git && \
    cd libvips && \
    ./autogen.sh && make && make install && cd .. && rm -rf libvips

ENV VIPSHOME /usr/local
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:${VIPSHOME}/lib
ENV PATH $PATH:${VIPSHOME}/bin
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:${VIPSHOME}/lib/pkgconfig

RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.5.0/herokuish_0.5.0_linux_x86_64.tgz" \
    --silent -L | tar -xzC /bin

RUN /bin/herokuish buildpack install \
  && ln -s /bin/herokuish /build \
  && ln -s /bin/herokuish /start \
  && ln -s /bin/herokuish /exec

RUN addgroup --quiet --gid "32767" "herokuishuser" \
  && adduser \
      --shell /bin/bash \
      --disabled-password \
      --force-badname \
      --no-create-home \
      --uid "32767" \
      --gid "32767" \
      --gecos '' \
      --quiet \
      --home "/app" \
      "herokuishuser"

RUN chown -R 32767:32767 /app
