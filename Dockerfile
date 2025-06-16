# Stage 1: The Builder Stage
# We use a Maven image to download the JAR file from Maven Central.
# This keeps our final image clean and only contains the necessary artifact.
ARG GUACAMOLE_VERSION=1.5.5

# renovate: datasource=maven depName=org.apache.guacamole:guacamole-auth-sso-openid
ARG OPENID_SSO_VERSION=1.5.5
FROM maven:3.8.5-openjdk-11 AS builder

# Set the version of the OpenID SSO extension as an argument
# RenovateBot can be configured to automatically update this version.
ARG OPENID_SSO_VERSION

# Set the working directory
WORKDIR /usr/src/app

# This is a trick to download the dependency without needing a full pom.xml file.
# The `get` goal will resolve and download the artifact and its dependencies.
# We specify the artifact by its group, artifactId, and version.
RUN mvn org.apache.maven.plugins:maven-dependency-plugin:3.3.0:get \
    -DrepoUrl=https://repo1.maven.org/maven2/ \
    -Dartifact=org.apache.guacamole:guacamole-auth-sso-openid:${OPENID_SSO_VERSION} \
    -Ddest=guacamole-auth-sso-openid.jar

# ---

# Stage 2: The Final Image
# We use the official Guacamole image as our base.
FROM guacamole/guacamole:${GUACAMOLE_VERSION}

# The user running Guacamole is `root` inside the container initially,
# and directories are owned by `root`. We need to ensure permissions are correct.
# The GUACAMOLE_HOME environment variable is set to /etc/guacamole by default.
# The extensions directory is expected to be in $GUACAMOLE_HOME/extensions

# Set the version of the OpenID SSO extension again
ARG OPENID_SSO_VERSION

# Create the target directory for the custom extension.
# The official Guacamole image will automatically load extensions from this directory.
# Using /opt/ is a common practice for add-on software.
# We are creating it inside GUACAMOLE_HOME so Guacamole can find it.
# The standard location is /etc/guacamole/extensions
RUN mkdir -p /etc/guacamole/extensions

# Copy the JAR from the builder stage to the extensions directory in the final image.
COPY --from=builder /usr/src/app/guacamole-auth-sso-openid.jar /etc/guacamole/extensions/guacamole-auth-sso-openid-${OPENID_SSO_VERSION}.jar

# You can add more configuration here if needed, for example, copying a guacamole.properties file.
# COPY guacamole.properties /etc/guacamole/guacamole.properties
