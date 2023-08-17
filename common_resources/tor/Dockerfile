FROM dockage/alpine:3.16.2-openrc

COPY assets/root/ /

RUN apk --no-cache --update --upgrade add tor privoxy socat \
    && mv /etc/privoxy/default.action.new /etc/privoxy/default.action \
    && mv /etc/privoxy/user.action.new /etc/privoxy/user.action \
    && mv /etc/privoxy/default.filter.new /etc/privoxy/default.filter \
    && mv /etc/privoxy/user.filter.new /etc/privoxy/user.filter \
    && mv /etc/privoxy/regression-tests.action.new /etc/privoxy/regression-tests.action \
    && mv /etc/privoxy/trust.new /etc/privoxy/trust \
    && mv /etc/privoxy/match-all.action.new /etc/privoxy/match-all.action \
    && mkdir /etc/torrc.d \
    && rc-update add tor \
    && rc-update add privoxy \
    && rc-update add socat

EXPOSE 9050/tcp 9051/tcp 8118/tcp
