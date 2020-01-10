FROM alpine:latest

RUN apk add --no-cache hugo

COPY . /hugo
WORKDIR /hugo

EXPOSE 80

CMD hugo serve -p 80 --bind 0.0.0.0 -b https://mnavarro.dev