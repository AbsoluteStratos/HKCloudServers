FROM alpine:3.18.4
LABEL author="Stratos"
LABEL desc="Hollow Knight Multiplayer Docker"

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ mono bash curl screen unzip

ENV HKCS_VERSION="0.1.0"
ENV HKMP_OPT="/opt/hkmp"
ENV HKMP_HOME="/home/hkmp"
ENV HKMP_EXE="${HKMP_OPT}/HKMPServer.exe"
ENV HKMP_PBD="${HKMP_OPT}/HKMPServer.pdb"
ENV PORT="2222"

RUN mkdir /opt/hkmp
RUN mkdir /home/hkmp

# Download and extract hmkp into docker
WORKDIR /opt/hkmp
RUN curl -o HKMPServer.zip -sOL https://github.com/AbsoluteStratos/HKCloudServers/releases/download/$HKCS_VERSION/HKMPServer.zip
RUN unzip -o HKMPServer.zip

COPY hkmp.sh hkmp.sh
RUN chmod +x /opt/hkmp/hkmp.sh
RUN echo 'alias hkmp="/opt/hkmp/hkmp.sh"' >> ~/.bashrc

WORKDIR /home/hkmp
SHELL ["/bin/bash"]
CMD ["/opt/hkmp/hkmp.sh" "start"]