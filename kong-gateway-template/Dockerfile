FROM kong:latest

# Install the js-pluginserver
USER root
RUN apt update && apt install curl -y && curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt install nodejs -y && npm install -g kong-pdk

USER kong
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
