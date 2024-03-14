#########################################################
# Create an extensible SoapUI mock service runner image #
#########################################################

# Creating a JRE
FROM eclipse-temurin:11-jre-alpine

LABEL maintainer="Andreas Mersch <andreas.mersch@idesis.de>"
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"

##########################################################
# Download and unpack soapui
##########################################################

RUN addgroup --gid "1000" --system soapui
RUN adduser --uid "1000" --ingroup "soapui" --home "/home/soapui" --system --disabled-password soapui

RUN apk update \
    && apk add --allow-untrusted \
        curl \
    && apk cache clean


RUN curl -kLO https://dl.eviware.com/soapuios/5.7.2/SoapUI-5.7.2-linux-bin.tar.gz && \
    echo "0cffcbee929bd2abb484f7ab0e8ad495  SoapUI-5.7.2-linux-bin.tar.gz" >> MD5SUM && \
    md5sum -c MD5SUM && \
    tar -xzf SoapUI-5.7.2-linux-bin.tar.gz -C /home/soapui && \
    rm -f SoapUI-5.7.2-linux-bin.tar.gz MD5SUM

RUN chown -R soapui:soapui /home/soapui
RUN find /home/soapui -type d -exec chmod 770 {} \;
RUN find /home/soapui -type f -exec chmod 660 {} \;

############################################
# Setup MockService runner
############################################

USER soapui
ENV HOME /home/soapui
ENV SOAPUI_DIR /home/soapui/SoapUI-5.7.2
ENV SOAPUI_PRJ /home/soapui/soapui-prj

############################################
# Add customization sub-directories (for entrypoint)
############################################
ADD docker-entrypoint-initdb.d  /docker-entrypoint-initdb.d
ADD soapui-prj                  $SOAPUI_PRJ

############################################
# Expose ports and start SoapUI mock service
############################################
USER root

EXPOSE 8080

COPY docker-entrypoint.sh /
RUN chown -R soapui:soapui /docker-entrypoint.sh
RUN chmod 700 /docker-entrypoint.sh
RUN chmod 770 $SOAPUI_DIR/bin/*.sh

RUN chown -R soapui:soapui $SOAPUI_PRJ
RUN find $SOAPUI_PRJ -type d -exec chmod 770 {} \;
RUN find $SOAPUI_PRJ -type f -exec chmod 660 {} \;


############################################
# Start SoapUI mock service runner
############################################

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start-soapui"]
#CMD ["su", "-s", "/bin/sh", "soapui"]
