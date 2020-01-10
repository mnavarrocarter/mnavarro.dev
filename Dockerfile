FROM alpine:latest AS builder

RUN apk add --no-cache hugo

COPY . /hugo
WORKDIR /hugo

RUN hugo -D

FROM nginx:alpine
RUN rm /usr/share/nginx/html/index.html
COPY --from=builder /hugo/public /usr/share/nginx/html