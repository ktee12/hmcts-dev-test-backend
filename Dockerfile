FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace

COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle* ./

RUN chmod +x gradlew

COPY src src

RUN ./gradlew clean bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine

RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup appuser

WORKDIR /app

COPY --from=build \
    --chown=appuser:appgroup \
    /workspace/build/libs/test-backend.jar \
    /app/test-backend.jar

USER appuser

EXPOSE 4000

ENTRYPOINT ["java", "-jar", "/app/test-backend.jar"]