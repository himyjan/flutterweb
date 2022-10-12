FROM ubuntu:focal AS builder

# Setup
RUN apt-get update && apt-get install -y unzip xz-utils git openssh-client curl && apt-get upgrade -y && rm -rf /var/cache/apt

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter channel stable
# RUN flutter channel beta
RUN flutter upgrade
RUN flutter config --enable-web
RUN flutter doctor -v

# Copy files to container and get dependencies
WORKDIR /usr/local/bin/app
COPY . .
RUN flutter pub get
RUN flutter pub run build_runner build --delete-conflicting-outputs
RUN flutter build web

FROM alpine:latest

RUN apk update \
    && apk upgrade \
    && apk add --update lighttpd \
    && rm -rf /var/cache/apk/*

# Deploy with NGNIX
FROM nginx:latest
WORKDIR /usr/share/nginx/html
COPY --from=builder /usr/local/bin/app/build/web /var/www
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 3000
ENTRYPOINT ["nginx","-g","daemon off;"]

## Deploy with lighttpd
# COPY ./lighttpd/ /etc/lighttpd/
# WORKDIR /var/www/html
# COPY --from=builder /usr/local/bin/app/build/web .
# EXPOSE 8084
# ENTRYPOINT ["lighttpd","-D","-f","/etc/lighttpd/lighttpd.conf"]