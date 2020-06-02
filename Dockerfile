FROM wordpress:latest
RUN apt-get update
RUN apt-get -y install unzip

RUN rm -rf /var/www/html/*
ADD $HTML_DIR /var/www/html/
RUN chown -R www-data:www-data /var/www/html/cms/wp-content

ENV HOST 0.0.0.0
