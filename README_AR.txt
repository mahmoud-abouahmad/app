إصلاح فشل البناء — v1.4.1 المجاني

سبب الخطأ:
تم استدعاء دالة باسم confirmAction غير موجودة في المشروع.

الإصلاح:
- استبدالها بدالة deleteDocument الموجودة أصلًا.
- الإبقاء على نافذة تأكيد حذف الدرس.
- رفع الإصدار إلى 1.2.1+9.
- لا يحتاج Firebase Storage أو خطة Blaze.

خطوات الاستبدال:
1. فك ضغط الحزمة.
2. انسخ محتويات mahmoud_fix_v1_4_1_free إلى جذر مشروع app.
3. وافق على استبدال:
   lib/main.dart
   pubspec.yaml
4. في GitHub Desktop اكتب:
   Fix lesson delete build error
5. Commit to main ثم Push origin.
6. انتظر GitHub Actions.
