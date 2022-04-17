FROM nginx:latest

COPY ./etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Nuke the existing conf.d directoy and replace it with our own.
RUN rm -r /etc/nginx/conf.d
COPY ./etc/nginx/conf.d /etc/nginx/conf.d

COPY ./webroot /webroot
