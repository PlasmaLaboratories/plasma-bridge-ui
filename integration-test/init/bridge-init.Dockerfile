FROM eclipse-temurin:11-jdk

RUN apt update \
    && apt install --no-install-recommends -y curl gzip wget openssl \
    && apt-get clean

RUN mkdir /bitcoin && wget -qO- https://bitcoin.org/bin/bitcoin-core-27.0/bitcoin-27.0-x86_64-linux-gnu.tar.gz | tar xvz -C /bitcoin && install -m 0755 -o root -g root -t /usr/local/bin /bitcoin/bitcoin-27.0/bin/*

RUN curl -fL --proto "=https" "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > /usr/bin/cs && \
    chmod +x /usr/bin/cs

#This is the default user created by sbt-native-packager and is needed to permit the Bridge to modify the wallet DB file
USER root
# RUN id -u demiourgos728 1>/dev/null 2>&1 || (( getent group 0 1>/dev/null 2>&1 || ( type groupadd 1>/dev/null 2>&1 && groupadd -g 0 root || addgroup -g 0 -S root )) && ( type useradd 1>/dev/null 2>&1 && useradd --system --create-home --uid 1001 --gid 0 demiourgos728 || adduser -S -u 1001 -G root demiourgos728 ))
RUN useradd --system --create-home --uid 1001 --gid 0 demiourgos728

RUN mkdir -p /app/wallet && chown -R demiourgos728:root /app && chmod -R 775 /app

USER 1001:0

RUN cs setup --yes
RUN cs fetch -r https://s01.oss.sonatype.org/content/repositories/releases co.topl:brambl-cli_2.13:2.0.0-beta5

COPY extract_group_series_id.sh /extract_group_series_id.sh

ENTRYPOINT ["sh", "/bridge_init.sh"]
CMD []
