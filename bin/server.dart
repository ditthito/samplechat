import 'dart:io';
import 'dart:async';

const int serverPort = 8080;
List<WebSocket> connections;

main() async {
  final bool releaseStatus = false;

  String webPath = '.';
  String dotJS = '';
  if (releaseStatus) {
    webPath = './build';
    dotJS = '.js';
  }

  var indexHtml =  await new File('${webPath}/web/index.html').readAsString();
  var mainDart = await new File('${webPath}/web/main.dart${dotJS}').readAsString();
  var normalizeCss = await new File('${webPath}/web/css/normalize.css').readAsString();
  var skeletonCss = await new File('${webPath}/web/css/skeleton.css').readAsString();
  var stylesCss = await new File('${webPath}/web/css/styles.css').readAsString();
  var faviconPng = await new File('${webPath}/web/images/favicon.png');
  Future faviconPngBytes = faviconPng.readAsBytes();
  var browserPackage = await new File('${webPath}/web/packages/browser/dart.js').readAsString();

  connections = new List<WebSocket>();

  var server = await HttpServer.bind(InternetAddress.ANY_IP_V4, serverPort);
  print('Listening and serving HTTP on ${server.address.host}:${server.port}');
  await for (HttpRequest request in server) {
    switch (request.uri.toString()) {
      case '/':
        request.response
          ..headers.contentType = new ContentType("text", "html", charset: "utf-8")
          ..write(indexHtml)
          ..close();
        break;
      case '/css/normalize.css':
        request.response
          ..headers.contentType = new ContentType("text", "css", charset: "utf-8")
          ..write(normalizeCss)
          ..close();
        break;
      case '/css/skeleton.css':
        request.response
          ..headers.contentType = new ContentType("text", "css", charset: "utf-8")
          ..write(skeletonCss)
          ..close();
        break;
      case '/css/styles.css':
        request.response
          ..headers.contentType = new ContentType("text", "css", charset: "utf-8")
          ..write(stylesCss)
          ..close();
        break;
      case '/images/favicon.png':
        request.response
          ..headers.contentType = new ContentType("image", "png")
          ..addStream(faviconPngBytes.asStream()).whenComplete(() {
            request.response.close();
          });
        break;
      case '/main.dart.js':
        request.response
          ..headers.contentType = new ContentType("text", "javascript", charset: "utf-8")
          ..write(mainDart)
          ..close();
        break;
      case '/main.dart':
        request.response
          ..headers.contentType = new ContentType("text", "javascript", charset: "utf-8")
          ..write(mainDart)
          ..close();
        break;
      case '/packages/browser/dart.js':
        request.response
          ..headers.contentType = new ContentType("text", "javascript", charset: "utf-8")
          ..write(browserPackage)
          ..close();
        break;
      case '/ws':
        var socket = await WebSocketTransformer.upgrade(request);
        connections.add(socket);
        socket.listen((String msg) {
          print('Message received: ${msg}');
          for (WebSocket connection in connections) {
            connection.add(msg);
          }
        },
        onDone: () {
          connections.remove(socket);
          print('Client disconnected, there are now ${connections.length} client(s) connected.');
        });
        break;
      default:
        request.response
        ..headers.contentType = new ContentType("text", "html", charset: "utf-8")
        ..write('<h2>The web page not found.</h2>')
        ..close();
    }
  }
}
