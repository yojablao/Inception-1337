FROM debian:bookworm

RUN apt update && apt upgrade -y

RUN    apt install mariadb-server mariadb-client -y

COPY ./tools/m_db.sh .

RUN chmod +x ./m_db.sh

# EXPOSE 3306
ENTRYPOINT ["./m_db.sh"]