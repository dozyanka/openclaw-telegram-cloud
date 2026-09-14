FROM ghcr.io/openclaw/openclaw:2026.9.4

USER node
WORKDIR /home/node/cloud-bot

COPY --chown=node:node start.sh /home/node/cloud-bot/start.sh
COPY --chown=node:node workspace /home/node/cloud-workspace

RUN chmod 700 /home/node/cloud-bot/start.sh

ENTRYPOINT ["/home/node/cloud-bot/start.sh"]
