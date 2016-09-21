import 'dart:html';
import 'dart:async';

WebSocket ws;

void outputMsg(String msg) {
  TextAreaElement outputBox = querySelector('textarea#outputBox');
  var text = msg;
  if (outputBox.text.isNotEmpty) {
    text = "${outputBox.text}\n${text}";
  }
  outputBox.text = text;
  outputBox.scrollTop = outputBox.scrollHeight;
}

void sendMsg() {
  TextInputElement inputBox = querySelector('input#inputBox');
  if (inputBox.value.isNotEmpty) {
    ws.send(inputBox.value);
    inputBox.value = "";
  }
}

void handleKeyEvent(KeyboardEvent event) {
  if (event.keyCode == KeyCode.ENTER) {
    sendMsg();
  }
}

void initWebSocket([int retrySeconds = 2]) {
  var reconnectScheduled = false;

  outputMsg("Connecting to websocket");
  ws = new WebSocket('ws://${Uri.base.host}:${Uri.base.port}/ws');

  void scheduleReconnect() {
    if (!reconnectScheduled) {
      new Timer(new Duration(milliseconds: 1000 * retrySeconds), () => initWebSocket(retrySeconds * 2));
    }
    reconnectScheduled = true;
  }

  ws.onOpen.listen((e) {
    outputMsg('Connected');
  });

  ws.onMessage.listen((MessageEvent e) {
    outputMsg('${e.data}');
  });

  ws.onClose.listen((e) {
    outputMsg('Disconnect, retrying in $retrySeconds seconds');
    scheduleReconnect();
  });

  ws.onError.listen((e) {
    outputMsg("Error connecting");
    scheduleReconnect();
  });
}

void main() {
  initWebSocket();
  querySelector('input#inputBox').onKeyPress.listen(handleKeyEvent);
  querySelector('button#sendButton').onClick.listen((e) => sendMsg());
}
