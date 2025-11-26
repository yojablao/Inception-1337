FROM debian:bookworm

RUN apt update && apt upgrade -y && \
    apt install mariadb-server mariadb-client netcat-traditional -y

COPY ./tools/m_db.sh .

RUN chmod +x ./m_db.sh

# EXPOSE 3306
ENTRYPOINT ["./m_db.sh"]