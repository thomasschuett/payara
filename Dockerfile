FROM dreamit/centos-jreheadless:latest
MAINTAINER thomas.schuett@dreamit.de
LABEL io.openshift.tags   payara,glassfish
LABEL io.k8s.description Payara Server base install
LABEL io.openshift.expose-services 4848/https,8009:jmx,8080:http,8081:https
ENV container docker
ENV PAYARA_PATH=/opt/payara/payara41
ENV PATH $PAYARA_PATH/bin:$PATH
ENV PAYARA_VERSION=4.1.1.161
RUN yum -y install unzip
# create user
RUN useradd -d /opt/payara -m payara
# Chance to user
WORKDIR /opt/payara
USER payara
RUN curl  --output payara.zip https://s3-eu-west-1.amazonaws.com/payara.co/Payara+Downloads/Payara+$PAYARA_VERSION/payara-$PAYARA_VERSION.zip
RUN unzip payara.zip
RUN rm payara.zip

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
CMD $PAYARA_PATH/bin/asadmin start-domain && tail -f $PAYARA_PATH/glassfish/domains/domain1/logs/server.log
