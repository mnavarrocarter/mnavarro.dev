FROM klakegg/hugo:0.62.2-onbuild AS hugo

FROM nginx:alpine
RUN rm /usr/share/nginx/html/index.html
COPY --from=hugo /onbuild /usr/share/nginx/html