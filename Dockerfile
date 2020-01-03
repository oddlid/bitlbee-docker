FROM alpine:latest as builder
LABEL maintainer=stevesbrain,realies,oddlid

ENV BITLBEE_COMMIT 3a547ee9dcf5c790f68ee2118389dd27ed471b23
ENV DISCORD_COMMIT bc967eb6ab1bd98ea9f5d90eb567e41bb92e6391
ENV FACEBOOK_COMMIT c76b36bd29ee8b32fd038c7b7254931c71ecce1b
ENV SKYPE_COMMIT 09f72e27eb2ee129959de2b8eb7a1fd2c2830369
ENV SLACK_COMMIT be97802c7fd0b611722d2f551756e2a2672f6084
ENV STEAM_COMMIT a6444d2
ENV TELEGRAM_COMMIT 44a1349bf4c57e8b648dae113ec7cf3bdbde0789

ENV STRIP true

RUN set -x \
	&& apk update \
	&& apk upgrade \
	&& apk add --virtual build-dependencies \
	autoconf \
	automake \
	build-base \
	curl \
	git \
	gnutls-dev \
	json-glib-dev \
	libgcrypt-dev \
	libtool \
	libwebp-dev \
	pidgin-dev \
	python2
RUN cd /root \
	&& git clone -n https://github.com/bitlbee/bitlbee \
	&& cd bitlbee \
	&& git checkout ${BITLBEE_COMMIT} \
	&& mkdir /bitlbee-data \
	&& ./configure --purple=1 --config=/bitlbee-data \
	&& make \
	&& cp bitlbee / \
	&& make install \
	&& make install-dev \
	&& make install-etc \
	&& if [ "$STRIP" == "true" ]; then strip /usr/local/sbin/bitlbee; fi

FROM builder as discord-builder
RUN cd /root \
	&& git clone -n https://github.com/sm00th/bitlbee-discord \
	&& cd bitlbee-discord \
	&& git checkout ${DISCORD_COMMIT} \
	&& ./autogen.sh \
	&& ./configure \
	&& make \
	&& make install \
	&& if [ "$STRIP" == "true" ]; then strip /usr/local/lib/bitlbee/discord.so; fi

FROM builder as facebook-builder
RUN cd /root \
	&& git clone -n https://github.com/jgeboski/bitlbee-facebook \
	&& cd bitlbee-facebook \
	&& git checkout ${FACEBOOK_COMMIT} \
	&& ./autogen.sh \
	&& make \
	&& make install \
	&& if [ "$STRIP" == "true" ]; then strip /usr/local/lib/bitlbee/facebook.so; fi


FROM builder as skype-builder
RUN cd /root \
	&& git clone -n https://github.com/EionRobb/skype4pidgin \
	&& cd skype4pidgin \
	&& git checkout ${SKYPE_COMMIT} \
	&& cd skypeweb \
	&& make \
	&& make install \
	&& if [ "$STRIP" == "true" ]; then strip /usr/lib/purple-2/libskypeweb.so; fi

FROM builder as slack-builder
RUN cd /root \
	&& git clone -n https://github.com/dylex/slack-libpurple \
	&& cd slack-libpurple \
	&& git checkout ${SLACK_COMMIT} \
	&& make \
	&& mkdir -p /usr/share/pixmaps/pidgin/protocols/16/ \
	&& mkdir -p /usr/share/pixmaps/pidgin/protocols/22/ \
	&& mkdir -p /usr/share/pixmaps/pidgin/protocols/48/ \
	&& make install \
	&& if [ "$STRIP" == "true" ]; then strip /usr/lib/purple-2/libslack.so; fi

FROM builder as steam-builder
RUN cd /root \
	&& git clone -n https://github.com/bitlbee/bitlbee-steam \
	&& cd bitlbee-steam \
	&& git checkout ${STEAM_COMMIT} \
	&& ./autogen.sh \
	&& make \
	&& make install \
	&& if [ "$STRIP" == "true" ]; then strip /usr/local/lib/bitlbee/steam.so; fi

FROM builder as telegram-builder
RUN cd /root \
	&& git clone -n https://github.com/majn/telegram-purple \
	&& cd telegram-purple \
	&& git checkout ${TELEGRAM_COMMIT} \
	&& git submodule update --init --recursive \
	&& ./configure \
	&& make \
	&& make install \
	&& if [ "$STRIP" == "true" ]; then strip /usr/lib/purple-2/telegram-purple.so; fi

FROM alpine:latest
LABEL maintainer=stevesbrain,realies

RUN apk update
RUN apk upgrade
RUN apk add \
	glib \
	gnutls \
	json-glib \
	libgcrypt \
	libpurple \
	libpurple-bonjour \
	libpurple-oscar \
	libpurple-xmpp \
	libwebp \
	pidgin \
	&& adduser -u 1000 -S bitlbee \
	&& addgroup -g 1000 -S bitlbee \
	&& mkdir /bitlbee-data \
	&& chown -R bitlbee:bitlbee /bitlbee-data \
	&& touch /var/run/bitlbee.pid \
	&& chown bitlbee:bitlbee /var/run/bitlbee.pid

COPY --from=builder /usr/local/etc/bitlbee/ /usr/local/etc/bitlbee/
COPY --from=builder /usr/local/include/bitlbee/ /usr/local/include/bitlbee/
COPY --from=builder /usr/local/lib/pkgconfig/bitlbee.pc /usr/local/lib/pkgconfig/bitlbee.pc
COPY --from=builder /usr/local/sbin/bitlbee /usr/local/sbin/bitlbee
COPY --from=builder /usr/local/share/bitlbee/help.txt /usr/local/share/bitlbee/help.txt

COPY --from=discord-builder /usr/local/lib/bitlbee/discord.* /usr/local/lib/bitlbee/
COPY --from=discord-builder /usr/local/share/bitlbee/discord-help.txt /usr/local/share/bitlbee/discord-help.txt

COPY --from=facebook-builder /usr/local/lib/bitlbee/facebook.* /usr/local/lib/bitlbee/

COPY --from=skype-builder /usr/lib/purple-2/libskypeweb.so /usr/lib/purple-2/libskypeweb.so
COPY --from=skype-builder /usr/share/pixmaps/pidgin/emotes/skype/theme /usr/share/pixmaps/pidgin/emotes/skype/theme
# don't copy pixmaps. these are not needed for bitlbee
# COPY --from=skype-builder /usr/share/pixmaps/pidgin/protocols/16/skype* /usr/share/pixmaps/pidgin/protocols/16/
# COPY --from=skype-builder /usr/share/pixmaps/pidgin/protocols/22/skype* /usr/share/pixmaps/pidgin/protocols/22/
# COPY --from=skype-builder /usr/share/pixmaps/pidgin/protocols/48/skype* /usr/share/pixmaps/pidgin/protocols/48/

COPY --from=slack-builder /usr/lib/purple-2/libslack.so /usr/lib/purple-2/libslack.so
# COPY --from=slack-builder /usr/share/pixmaps/pidgin/protocols/16/slack.png /usr/share/pixmaps/pidgin/protocols/16/slack.png
# COPY --from=slack-builder /usr/share/pixmaps/pidgin/protocols/22/slack.png /usr/share/pixmaps/pidgin/protocols/22/slack.png
# COPY --from=slack-builder /usr/share/pixmaps/pidgin/protocols/48/slack.png /usr/share/pixmaps/pidgin/protocols/48/slack.png

COPY --from=steam-builder /usr/local/lib/bitlbee/steam.* /usr/local/lib/bitlbee/

# @2020-01-03: server.tglpub doesn't exist in current build, so uncommenting
#COPY --from=telegram-builder /etc/telegram-purple/server.tglpub /etc/telegram-purple/server.tglpub
COPY --from=telegram-builder /usr/lib/purple-2/telegram-purple.so /usr/lib/purple-2/telegram-purple.so

USER bitlbee
VOLUME /bitlbee-data
ENTRYPOINT ["/usr/local/sbin/bitlbee", "-F", "-n", "-d", "/bitlbee-data"]
