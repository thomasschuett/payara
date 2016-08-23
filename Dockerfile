FROM openshift/centos-jreheadless:latest
MAINTAINER thomas.schuett@dreamit.de
LABEL io.openshift.tags   payara,glassfish
LABEL io.k8s.description Payara Server base install
LABEL io.openshift.expose-services 4848/https,8009:jmx,8080:http,8081:https
LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i
ENV container docker
ENV PAYARA_PATH=/opt/payara/payara41
ENV PATH $PAYARA_PATH/bin:$PATH
ENV PAYARA_VERSION=4.1.1.161
RUN yum -y install unzip
# s2i hooks
RUN mkdir -p /usr/libexec/s2i && \
  echo "#!/bin/sh" > /usr/libexec/s2i/assemble-runtime && \
  chmod 775 /usr/libexec/s2i/assemble-runtime && \
  echo "#!/bin/sh" && \
  chmod 775 /usr/libexec/s2i/run
# create user
RUN useradd -d /opt/payara -g 0 -u 4711 -m payara
# Change to user
WORKDIR /opt/payara
USER 4711
RUN curl  --output payara.zip https://s3-eu-west-1.amazonaws.com/payara.co/Payara+Downloads/Payara+$PAYARA_VERSION/payara-$PAYARA_VERSION.zip && \
  unzip payara.zip && \
  rm payara.zip
EXPOSE 4848 8009 8080 8181
# set credentials to admin/admin 

RUN echo -e 'AS_ADMIN_PASSWORD=\n\
AS_ADMIN_NEWPASSWORD=admin\n\
EOF\n'\
>> /tmp/passwd

RUN echo -e 'AS_ADMIN_PASSWORD=admin\n\
EOF\n'\
>> /tmp/passwd

RUN cat /tmp/passwd
RUN \
 $PAYARA_PATH/bin/asadmin start-domain && \
 $PAYARA_PATH/bin/asadmin --user admin --passwordfile=/tmp/passwd change-admin-password && \
 $PAYARA_PATH/bin/asadmin --user admin --passwordfile=/tmp/passwd enable-secure-admin && \
 $PAYARA_PATH/bin/asadmin stop-domain
RUN rm /tmp/passwd 
CMD $PAYARA_PATH/bin/asadmin start-domain --verbose
