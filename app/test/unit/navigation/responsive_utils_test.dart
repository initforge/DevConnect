import 'package:devconnect/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detects mobile breakpoint', (tester) async {
    await tester.pumpWidget(_withWidth(390));
    expect(_deviceType(tester), DeviceType.mobile);
  });

  testWidgets('detects tablet breakpoint', (tester) async {
    await tester.pumpWidget(_withWidth(768));
    expect(_deviceType(tester), DeviceType.tablet);
  });

  testWidgets('detects desktop breakpoint', (tester) async {
    await tester.pumpWidget(_withWidth(1440));
    expect(_deviceType(tester), DeviceType.desktop);
  });
}

Widget _withWidth(double width) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Builder(
        builder: (context) => Text(ResponsiveUtils.getDeviceType(context).name),
      ),
    ),
  );
}

DeviceType _deviceType(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text));
  return DeviceType.values.byName(text.data!);
}
