FROM klakegg/hugo:0.62.2-onbuild AS hugo

FROM nginx:alpine
COPY --from=hugo /onbuild /usr/share/nginx/html
