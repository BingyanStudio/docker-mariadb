FROM alpine:3.3

ENV MARIADB_VERSION 10.1.12
ENV TERM xterm

ENV MYSQL_ENV_FILE ""
ENV MYSQL_ROOT_PASSWORD ""
ENV MYSQL_USER ""
ENV MYSQL_PASSWORD ""
ENV MYSQL_DATABASE ""

RUN apk update && \
    apk add 'mariadb<10.1.13' 'mariadb-client<10.1.13' && \
    sed -ri "s/^(bind-address|skip-networking|log-bin)/# \1/" /etc/mysql/my.cnf

EXPOSE 3306
VOLUME /var/lib/mysql

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["mysqld", "--user=mysql", "--socket=/var/lib/mysql/mysqld.sock"]
