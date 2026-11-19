# ---- Stage 1: build (JDK + Maven wrapper) ----
FROM registry.access.redhat.com/ubi9/openjdk-21:1.24 AS build
USER root
# mvnw needs unzip; without it, it downloads the .tar.gz and fails the .zip checksum check
RUN microdnf install -y unzip && microdnf clean all
WORKDIR /build
ENV MAVEN_OPTS="-Xmx512m"
COPY mvnw pom.xml ./
COPY .mvn .mvn
COPY src src
RUN chmod +x mvnw && ./mvnw -B package

# ---- Stage 2: runtime (JRE only, non-root) ----
FROM registry.access.redhat.com/ubi9/openjdk-21-runtime:1.24
ENV LANGUAGE='en_US:en'
COPY --from=build --chown=185 /build/target/quarkus-app/lib/ /deployments/lib/
COPY --from=build --chown=185 /build/target/quarkus-app/*.jar /deployments/
COPY --from=build --chown=185 /build/target/quarkus-app/app/ /deployments/app/
COPY --from=build --chown=185 /build/target/quarkus-app/quarkus/ /deployments/quarkus/
EXPOSE 8080
USER 185
ENV JAVA_OPTS_APPEND="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"
ENTRYPOINT [ "/opt/jboss/container/java/run/run-java.sh" ]
