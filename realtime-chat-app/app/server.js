const express = require("express");
const app = express();
const http = require("http").createServer(app);
const io = require("socket.io")(http, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});
const path = require("path");
const client = require("prom-client");

app.use(express.static(path.join(__dirname)));

client.collectDefaultMetrics();

const httpRequestDuration = new client.Histogram({
  name: "chat_app_http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
});

const socketConnectionsTotal = new client.Counter({
  name: "chat_app_socket_connections_total",
  help: "Total number of Socket.IO connections established",
});

const socketDisconnectionsTotal = new client.Counter({
  name: "chat_app_socket_disconnections_total",
  help: "Total number of Socket.IO disconnections",
});

const chatMessagesTotal = new client.Counter({
  name: "chat_app_messages_total",
  help: "Total number of chat messages sent",
});

const activeSocketConnections = new client.Gauge({
  name: "chat_app_active_socket_connections",
  help: "Current number of active Socket.IO connections",
});

const activeChatUsers = new client.Gauge({
  name: "chat_app_active_chat_users",
  help: "Current number of users that have joined the chat",
});

app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();

  res.on("finish", () => {
    const route = req.route?.path || req.path || "unknown";
    end({
      method: req.method,
      route,
      status_code: res.statusCode,
    });
  });

  next();
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

const users = {};

io.on("connection", (socket) => {
  socketConnectionsTotal.inc();
  activeSocketConnections.inc();

  socket.on("new-user", (name) => {
    users[socket.id] = name;
    activeChatUsers.set(Object.keys(users).length);
    socket.broadcast.emit("user-connected", name);
  });

  socket.on("send-chat-msg", (m) => {
    chatMessagesTotal.inc();
    var r = jsCrypto.crypto(m, "FcFLwoKAbZ");
    socket.broadcast.emit("chat-message", {
      message: jsCrypto.crypto(r, "INHiFpg22k"),
      name: users[socket.id],
    });
  });

  socket.on("disconnect", () => {
    socketDisconnectionsTotal.inc();
    activeSocketConnections.dec();
    socket.broadcast.emit("user-disconnected", users[socket.id]);
    delete users[socket.id];
    activeChatUsers.set(Object.keys(users).length);
  });
});

var jsCrypto = {
  crypto: function (s, k) {
    var enc = "";
    var str = s.toString();
    for (var i = 0; i < s.length; i++) {
      var a = s.charCodeAt(i);
      var b = a ^ k;
      enc = enc + String.fromCharCode(b);
    }
    return enc;
  },
};

const PORT = 3000;
http.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
});
