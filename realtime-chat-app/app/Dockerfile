# ---------- Build Stage ----------
FROM node:20.19.5-alpine3.22 AS build
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .

# ---------- Runtime Stage ----------
FROM node:20.19.5-alpine3.22
WORKDIR /app
RUN addgroup -S appgroup && \
  adduser -S appuser -G appgroup && \
  chown -R appuser:appgroup /app
COPY --from=build /app .
USER appuser
EXPOSE 3000
CMD ["npm", "run", "devStart"]
