FROM node:20.8.0-alpine

# Install tini to handle signals properly
# Ref: https://hynek.me/articles/docker-signals/
RUN apk add --no-cache tini

# specify tini as the entrypoint
# tini proxy signals to the node process
ENTRYPOINT ["/sbin/tini", "--"]

# Run the service
CMD ["./node_modules/.bin/tsx", "./src/service.ts"]
