FROM maven:3.8-jdk-11 as builder

WORKDIR /build
COPY ./app .
COPY ./scripts .
RUN apt-get update -y && apt-get upgrade -y && apt-get install vim rpm -y
RUN mvn install compile

FROM adoptopenjdk/openjdk11:x86_64-alpine-jre-11.0.5_10 as runner
WORKDIR /app
COPY --from=builder /build/target/letscodebyada-0.0.1-SNAPSHOT.jar app.jar
COPY --from=builder /build/startup.sh startup.sh


EXPOSE 8080

ENTRYPOINT ["/bin/sh", "startup.sh"]