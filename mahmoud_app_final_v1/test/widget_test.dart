import 'package:flutter_test/flutter_test.dart';
import 'package:mahmoud_math_app/main.dart';

void main() {
  test('Arabic class names and notification types are correct', () {
    expect(displayClassName('CLS-001'), 'مجموعة 27');
    expect(displayClassName('CLS-002'), 'مجموعة 28');
    expect(displayClassName('ALL'), 'كل المجموعات');
    expect(notificationTypeLabel('Homework'), 'واجب');
    expect(notificationTypeLabel('Quiz'), 'موعد مذاكرة');
    expect(notificationTypeLabel('Motivation'), 'تحفيز');
    expect(notificationTypeLabel('Important'), 'تنبيه مهم');
  });

  test('Arabic and Persian digits are parsed', () {
    expect(readDouble('١٢٫٥'), 12.5);
    expect(readDouble('۱۸.۵'), 18.5);
    expect(readDouble('20'), 20.0);
  });

  test('Only the approved WhatsApp number is configured', () {
    expect(teacherWhatsAppNumber, '0956268336');
    expect(teacherWhatsAppInternational, '963956268336');
  });
}
