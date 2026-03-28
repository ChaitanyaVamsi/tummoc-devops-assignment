const socket = io();
//This will auto-connect to the host that served the HTML file — ideal and flexible.

const messageContainer = document.getElementById("message-container");
const msgForm = document.getElementById("send-container");
const msgInput = document.getElementById("message-input");
const n = prompt("What is your name?");
appendMessage("You joined");
socket.emit("new-user", n);

socket.on("chat-message", (data) => {
  appendMessage(Jscrypto.crypto(data.message, "FcFLwoKAbZ"), false, data.name);
});

socket.on("user-connected", (x) => {
  appendMessage(`${x} connected`);
});

socket.on("user-disconnected", (x) => {
  appendMessage(`${x} disconnected`);
});

msgForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const msg = msgInput.value;
  var encrypted = Jscrypto.crypto(msg, "INHiFpg22k");
  appendMessage(msg, true, "You");
  socket.emit("send-chat-msg", encrypted);
  msgInput.value = "";
});

function appendMessage(message, isSelf = false, senderName = "") {
  const messageBlock = document.createElement("div");
  messageBlock.classList.add("message");

  if (!senderName) {
    const systemMessage = document.createElement("div");
    systemMessage.classList.add("system-message");
    systemMessage.innerText = message;
    messageBlock.appendChild(systemMessage);
  } else {
    messageBlock.classList.add(isSelf ? "self-message" : "other-message");

    const avatar = document.createElement("div");
    avatar.classList.add("avatar");
    avatar.innerText = senderName.charAt(0).toUpperCase();

    const textContainer = document.createElement("div");
    textContainer.classList.add("text-wrapper");

    const nameElement = document.createElement("div");
    nameElement.classList.add("sender-name");
    nameElement.innerText = senderName;

    const text = document.createElement("div");
    text.classList.add("message-text");
    text.innerText = message;

    const colorClass = `user-color-${hashColor(senderName)}`;
    text.classList.add(colorClass);
    nameElement.classList.add(colorClass);
    avatar.classList.add(colorClass);

    textContainer.appendChild(nameElement);
    textContainer.appendChild(text);

    messageBlock.appendChild(avatar);
    messageBlock.appendChild(textContainer);
  }

  messageContainer.appendChild(messageBlock);
  messageContainer.scrollTop = messageContainer.scrollHeight;
}

function hashColor(name) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return Math.abs(hash % 6); // You can increase range if you add more styles
}

var Jscrypto = {
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
