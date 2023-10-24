FROM openjdk:17

ENV TZ=Asia/Hong_Kong

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && apt-get -y upgrade 





# ADD  app.jar /app.jar

# ENV JAVA_OPTS=""

# VOLUME /backend

# ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar" ]
