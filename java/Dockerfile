# this file describes how to build tsuru java image
# to run it:
# 1- install docker
# 2- run: $ docker build --rm --no-cache -t tsuru/java https://raw.github.com/tsuru/basebuilder/master/java/Dockerfile

from	ubuntu:14.04

run	apt-get update
run	apt-get install wget curl -y --force-yes
RUN     curl -SL http://file.cloud.tsuru.cn/aliyun.list > /etc/apt/source.list
run	wget http://github.com/ChangjunZhao/basebuilder/tarball/java_datasource_support -O basebuilder.tar.gz --no-check-certificate
run	mkdir /var/lib/tsuru
run	tar -xvf basebuilder.tar.gz -C /var/lib/tsuru --strip 1
run	cp /var/lib/tsuru/java/deploy /var/lib/tsuru
run	cp /var/lib/tsuru/java/start /var/lib/tsuru
run	/var/lib/tsuru/java/install
