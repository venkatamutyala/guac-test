# Stage 1: The Downloader Stage
# We use a lightweight image with download tools to get the official binary release.
# This approach downloads the specific SSO extension bundle.

# Set the version for Guacamole. RenovateBot can use the release tags from the
# guacamole-client GitHub repository to suggest updates for this ARG.
# renovate: datasource=github-releases depName=apache/guacamole-client
ARG GUAC_VERSION=1.5.5

FROM debian:bullseye-slim AS downloader

# Install required tools for downloading and extracting
RUN apt-get update && apt-get install -y wget tar && rm -rf /var/lib/apt/lists/*

# Forward the version argument into this stage
ARG GUAC_VERSION

# Set the working directory
WORKDIR /tmp

# --- Debugging Step ---
RUN echo "Downloading Guacamole SSO binary version: ${GUAC_VERSION}"

# Download the official Guacamole SSO binary distribution from the Apache archives ref: https://guacamole.apache.org/releases/
RUN wget "https://archive.apache.org/dist/guacamole/${GUAC_VERSION}/binary/guacamole-auth-sso-${GUAC_VERSION}.tar.gz"

# Extract the archive to get access to the OpenID extension
RUN tar -xzf "guacamole-auth-sso-${GUAC_VERSION}.tar.gz"

# ---

# Stage 2: The Final Image
# We use the official Guacamole image as our base.
FROM guacamole/guacamole:${GUAC_VERSION}

# Forward the version argument into the final stage
ARG GUAC_VERSION

# Set the GUACAMOLE_HOME to the new directory so Guacamole can find its files.
ENV GUACAMOLE_HOME /home/guacamole

# Create the extensions directory inside our new GUACAMOLE_HOME.
RUN mkdir -p /home/guacamole/glueops/extensions

ENV GUACAMOLE_HOME /home/guacamole/glueops/

# Copy only the required OpenID SSO JAR from the downloader stage to the new extensions directory.
# The path reflects the structure of the guacamole-auth-sso archive.
COPY --from=downloader "/tmp/guacamole-auth-sso-${GUAC_VERSION}/openid/guacamole-auth-sso-openid-${GUAC_VERSION}.jar" $GUACAMOLE_HOME/extensions/


