FROM eclipse-temurin:17-jdk

ARG freenet_build

ENV allowedhosts=127.0.0.1,0:0:0:0:0:0:0:1 \
    darknetport=12345 \
    opennetport=12346

EXPOSE 80 9481 ${darknetport}/udp ${opennetport}/udp

# Install dependencies, nginx, and gosu
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl gnupg2 ca-certificates lsb-release nano net-tools openssl wget gosu && \
    echo "deb http://nginx.org/packages/ubuntu jammy nginx" \
        > /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Prepare directories and user
RUN mkdir -p /run/nginx /conf /data /download /fred && \
    addgroup --gid 1000 fred || true && \
    adduser --disabled-password --gecos "" --uid 1000 --gid 1000 --home /fred fred || true && \
    chown -R 1000:1000 /conf /data /download /fred

# Copy configs and scripts
COPY nginx.conf /etc/nginx/nginx.conf
COPY ./defaults/freenet.ini /defaults/
COPY docker-run /fred/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /fred/docker-run

WORKDIR /fred
VOLUME ["/conf", "/data", "/download"]

USER fred
# Get the latest freenet build or use supplied version
RUN set -e; \
    if [ -n "${freenet_build}" ]; then \
        build="${freenet_build}"; \
    else \
        build=$(wget -qO - https://api.github.com/repos/freenet/fred/releases/latest | grep 'tag_name'| cut -d'"' -f 4); \
    fi; \
    short_build=$(echo "${build}" | cut -c7-); \
    echo -e "build: $build\nurl: https://github.com/freenet/fred/releases/download/$build/new_installer_offline_$short_build.jar" > /fred/buildinfo.json; \
    echo "Building:"; \
    cat /fred/buildinfo.json; \
    wget -O /tmp/new_installer.jar "https://github.com/freenet/fred/releases/download/$build/new_installer_offline_$short_build.jar"; \
    echo "INSTALL_PATH=/fred/" > /tmp/install_options.conf; \
    java -jar /tmp/new_installer.jar -options /tmp/install_options.conf; \
    sed -i 's#wrapper.app.parameter.1=freenet.ini#wrapper.app.parameter.1=/conf/freenet.ini#' /fred/wrapper.conf; \
    rm /tmp/new_installer.jar /tmp/install_options.conf; \
    echo "Build successful"; \
    echo "----------------"; \
    cat /fred/buildinfo.json

ENV FREENET_VERSION=$build

USER root
# HEALTHCHECK --interval=5m --timeout=3s CMD /fred/run.sh status || exit 1

ENTRYPOINT ["/entrypoint.sh"]
