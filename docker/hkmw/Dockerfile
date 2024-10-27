FROM alpine:3.18.4
LABEL author="Stratos"
LABEL desc="Hollow Knight MultiWorld Docker"

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ mono bash curl screen unzip

ENV HKCS_VERSION="0.1.0"
ENV HKMW_OPT="/opt/hkmw"
ENV HKMW_HOME="/home/hkmw"
ENV HKMW_EXE="${HKMW_OPT}/MultiWorldServer.exe"
ENV HKMW_SEVER_NAME="Stratos ItemSync"
ENV PORT="3333"

RUN mkdir /opt/hkmw
RUN mkdir /home/hkmw

# Download and extract hmkp into docker
WORKDIR /opt/hkmw
RUN curl -o HKMWServer.zip -sOL https://github.com/AbsoluteStratos/HKCloudServers/releases/download/$HKCS_VERSION/HKMWServer.zip
RUN unzip -o HKMWServer.zip

COPY hkmw.sh hkmw.sh
RUN chmod +x /opt/hkmw/hkmw.sh
RUN echo 'alias hkmw="/opt/hkmw/hkmw.sh"' >> ~/.bashrc

WORKDIR /home/hkmw
SHELL ["/bin/bash"]
CMD ["/opt/hkmw/hkmw.sh", "start"]