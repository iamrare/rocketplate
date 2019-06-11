FROM golang:1.12-stretch

# For psql
RUN apt-get update && apt-get install -y postgresql postgresql-client

RUN go get github.com/elwinar/rambler

COPY migrations migrations
COPY apply-all.bash apply-all.bash
# COPY rambler.json ./

CMD env | grep RAMBLER && ./apply-all.bash
