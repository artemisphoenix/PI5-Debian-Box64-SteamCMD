FROM arm64v8/debian AS build
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install --yes --no-install-recommends git python3 build-essential cmake ca-certificates && \
    apt-get install --yes --no-install-recommends gcc-arm-linux-gnueabihf libc6-dev-armhf-cross libc6:armhf libstdc++6:armhf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN git clone https://github.com/ptitSeb/box86.git; mkdir /box86/build && \
    git clone https://github.com/ptitSeb/box64.git; mkdir /box64/build

WORKDIR /box86/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

WORKDIR /box64/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

FROM arm64v8/debian

COPY --from=build /tmp/install /

RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install --yes --no-install-recommends libc6:armhf libstdc++6:armhf && \
    apt-get -y autoremove && \
    apt-get clean autoclean && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists

RUN apt-get update && \
    apt-get install --yes --no-install-recommends software-properties-common && \
    dpkg --add-architecture i386 && \
    add-apt-repository -y -n -U http://deb.debian.org/debian -c non-free -c non-free-firmware && \
    add-apt-repository -y -n -U http://deb.debian.org/debian -c non-free -c non-free-firmware && \
    apt-get update && \
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt-get install --yes --no-install-recommends steamcmd

ENTRYPOINT ["box64"]
