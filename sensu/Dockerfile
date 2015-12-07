FROM centos
MAINTAINER Etki <etki@etki.name>

ENV EMBEDDED_RUBY=true PATH=$PATH:/opt/sensu/bin:/opt/sensu/embedded/bin \
    GEM_PATH=/opt/sensu/embedded/lib/ruby/gems/2.2.0:$GEM_PATH

WORKDIR /tmp

RUN curl -L -Ss http://repositories.sensuapp.org/yum/x86_64/sensu-0.21.0-2.x86_64.rpm > /tmp/sensu.rpm \
    && rpm2cpio /tmp/sensu.rpm | cpio -idm && mv /tmp/opt/sensu /opt/ \
    && mv /tmp/etc/sensu /etc/ \
    && rm -rf /tmp/var /tmp/usr /tmp/sensu.rpm /tmp/etc

WORKDIR /

ADD docker-ctl.sh /opt/sensu/bin/