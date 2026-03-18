FROM authelia/authelia:4.38

# Install gettext for envsubst, and bash for the entrypoint script
USER root
RUN apk add --no-cache bash gettext

# Copy templates and entrypoint
COPY templates/ /templates/
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Authelia config lives here — must be backed by a Railway volume
VOLUME ["/config"]

EXPOSE 9091

ENTRYPOINT ["/entrypoint.sh"]
