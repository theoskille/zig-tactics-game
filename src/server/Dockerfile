FROM alpine:latest

# Install Zig and build dependencies
RUN apk add --no-cache \
    zig \
    build-base \
    curl

WORKDIR /app

# Copy all server files
COPY . .

# Build using server build file
RUN zig build

EXPOSE 8080

# Run server executable
CMD ["./zig-out/bin/game-server"]