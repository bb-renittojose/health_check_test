#Stage 1 - Install dependencies and build the app in a build environment
FROM debian:latest AS build-env
# Install flutter dependencies
RUN apt-get update
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback python3 sed
RUN apt-get clean
# Clone the flutter repo
RUN git clone -b 3.3.2 https://github.com/flutter/flutter.git /usr/local/flutter
# Set flutter path
ENV PATH="${PATH}:/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin"
# Run flutter doctor
RUN flutter config --enable-web
RUN flutter doctor -v
#RUN flutter channel beta
#RUN flutter upgrade

##select specific version of flutter
#RUN flutter version v3.3.2
#RUN flutter flutter --version

# Copy files to container and build
RUN mkdir /app/
COPY . /app/
WORKDIR /app/

###for local build
#RUN flutter build web
#build web build in release mode with pwa disabled
#build with sourcemaps enabled for sentry logs --source-maps
RUN flutter build web --pwa-strategy=none

##Sentry for error reporting
##install sentry CLI
#RUN curl -sL https://sentry.io/get-cli/ | bash
#RUN sentry-cli --version
##upload source maps to sentry
#RUN sentry-cli releases files "npi_portal-1.0.0+1" upload-sourcemaps /app/build/web

# Stage 2 - Create web application server and the run-time image
FROM nginx:1.22
#RUN apt-get install nginx-plus-module-ndk
# drop symlinks - to get logs on specified files than stdout
#RUN unlink /var/log/nginx/access.log
#RUN unlink /var/log/nginx/error.log
#expose a custom port other than 80
EXPOSE 4000
#remove default nginx config files
#RUN rm /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf
#copy nginx config file to container to modify config to listen on port 3000, format log etc
COPY ./nginx.conf /etc/nginx/nginx.conf.template
#copy web build to /usr/share/nginx/html
RUN cd /usr/share/nginx/html
COPY --from=build-env /app/build/web /usr/share/nginx/html
##copy health check index.html file
RUN cd /usr/share/nginx/html
RUN mkdir health
COPY ./health /usr/share/nginx/html/health

CMD ["/bin/bash", "-c", "envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]