FROM openjdk:17-slim-bullseye

# Build argument (e.g. "build01478")
ARG freenet_build

# Runtime argument
ENV allowedhosts=127.0.0.1,0:0:0:0:0:0:0:1 darknetport=12345 opennetport=12346

# Interfaces:
EXPOSE 80 9481 ${darknetport}/udp ${opennetport}/udp

#nginx 
RUN apt update && \
    apt install -y nginx nano net-tools curl openssl wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/nginx
COPY nginx.conf /etc/nginx/nginx.conf


# Check every 5 Minutes, if Freenet is still running
#HEALTHCHECK --interval=5m --timeout=3s CMD /fred/run.sh status || exit 1

# Do not run freenet as root user:
RUN mkdir -p /conf /data && addgroup --gid 1000 fred && adduser --gid 1000 --home /fred fred && chown fred: /conf /data

COPY ./defaults/freenet.ini /defaults/
COPY docker-run /fred/

USER fred
WORKDIR /fred
VOLUME ["/conf", "/data"]

# Get the latest freenet build or use supplied version
RUN build=$(test -n "${freenet_build}" && echo ${freenet_build} \
            || wget -qO - https://api.github.com/repos/freenet/fred/releases/latest | grep 'tag_name'| cut -d'"' -f 4) \
    && short_build=$(echo ${build}|cut -c7-) \
    && echo -e "build: $build\nurl: https://github.com/freenet/fred/releases/download/$build/new_installer_offline_$short_build.jar" >buildinfo.json \
    && echo "Building:" \
    && cat buildinfo.json

ENV FREENET_VERSION=$build

# Download and install freenet in the given version
RUN wget -O /tmp/new_installer.jar $(grep url /fred/buildinfo.json |cut -d" " -f2) \
    && echo "INSTALL_PATH=/fred/" >/tmp/install_options.conf \
    && java -jar /tmp/new_installer.jar -options /tmp/install_options.conf \
    && sed -i 's#wrapper.app.parameter.1=freenet.ini#wrapper.app.parameter.1=/conf/freenet.ini#' /fred/wrapper.conf \
    && rm /tmp/new_installer.jar /tmp/install_options.conf \
    && echo "Build successful" \
    && echo "----------------" \
    && cat /fred/buildinfo.json

COPY entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
