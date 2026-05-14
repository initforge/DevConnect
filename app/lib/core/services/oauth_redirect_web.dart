// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void redirectToExternalUrl(String url) {
  html.window.location.assign(url);
}
