FROM ubuntu:latest
MAINTAINER  AMIRI <mohammed.amiri@ensg.eu>
RUN echo 'Acquire::http::proxy "http://10.0.4.2:3128/";' > /etc/apt/apt.conf.d/proxy.conf
RUN apt-get update && apt-get install -y libxml2-utils
ADD Validator.sh /home/Validator.sh
RUN chmod +x /home/Validator.sh
