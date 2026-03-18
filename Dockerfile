FROM authelia/authelia:4.38

# Install bash for the entrypoint script
USER root
RUN apk add --no-cache bash

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Authelia config dir — mount a Railway volume at /config
RUN mkdir -p /config

EXPOSE 9091

ENTRYPOINT ["/entrypoint.sh"]
