import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

const brandPurple = Color(0xFF3E276A);
const brandPurpleDark = Color(0xFF271745);
const brandGold = Color(0xFFC9A227);
const appBackground = Color(0xFFF7F5FA);
const appName = 'منصة الأستاذ محمود الدياب';
const slogan = 'نبدأ بالحلم ونصنع الإنجاز';
const logoAsset = 'assets/images/logo.png';
const teacherWhatsAppNumber = '0956268336';
const teacherWhatsAppInternational = '963956268336';
const appVersionLabel = '1.0.0';

String emailKey(String? email) => (email ?? '').trim().toLowerCase();

String studentDocumentId(String email) =>
    emailKey(email).replaceAll('.', '_').replaceAll('@', '_');

String displayClassName(String? classId) {
  switch ((classId ?? '').trim()) {
    case 'CLS-001':
      return 'مجموعة 27';
    case 'CLS-002':
      return 'مجموعة 28';
    case 'ALL':
      return 'كل المجموعات';
    default:
      return 'غير محددة';
  }
}

String arabicAttendanceStatus(String? status) =>
    status == 'Present' ? 'حاضرة' : 'غائبة';

String notificationTypeLabel(String? type) {
  switch (type) {
    case 'Motivation':
      return 'تحفيز';
    case 'Quiz':
      return 'موعد مذاكرة';
    case 'Homework':
      return 'واجب';
    case 'Important':
    default:
      return 'تنبيه مهم';
  }
}

IconData notificationTypeIcon(String? type) {
  switch (type) {
    case 'Motivation':
      return Icons.auto_awesome_outlined;
    case 'Quiz':
      return Icons.event_note_outlined;
    case 'Homework':
      return Icons.assignment_outlined;
    case 'Important':
    default:
      return Icons.priority_high_rounded;
  }
}

Color notificationTypeColor(String? type) {
  switch (type) {
    case 'Motivation':
      return const Color(0xFF2E7D32);
    case 'Quiz':
      return const Color(0xFF1565C0);
    case 'Homework':
      return const Color(0xFF6A1B9A);
    case 'Important':
    default:
      return const Color(0xFFC62828);
  }
}

int timestampMillis(dynamic value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  if (value is String) {
    return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
  }
  return 0;
}

String normalizeDigits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var output = value.trim().replaceAll(',', '.').replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) {
    output = output
        .replaceAll(arabic[i], '$i')
        .replaceAll(persian[i], '$i');
  }
  return output;
}

double? readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(normalizeDigits(value?.toString() ?? ''));
}

String displayNumber(dynamic value) {
  final number = readDouble(value);
  if (number == null) return value?.toString() ?? '-';
  if (number == number.roundToDouble()) return number.toInt().toString();
  return number.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String todayIso() => DateTime.now().toIso8601String().split('T').first;

Future<void> openTeacherWhatsApp(BuildContext context) async {
  final uri = Uri.https(
    'wa.me',
    '/$teacherWhatsAppInternational',
    <String, String>{
      'text': 'السلام عليكم أستاذ محمود، أتواصل معك من تطبيق منصة الأستاذ محمود الدياب.',
    },
  );

  try {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showErrorSnack(context, 'تعذر فتح واتساب على هذا الجهاز.');
    }
  } catch (exception) {
    if (context.mounted) {
      showErrorSnack(context, 'تعذر فتح واتساب: $exception');
    }
  }
}

Future<void> openExternalLink(BuildContext context, String rawUrl) async {
  var value = rawUrl.trim();
  if (value.isEmpty) return;
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'https://$value';
  }

  final uri = Uri.tryParse(value);
  if (uri == null) {
    if (context.mounted) showErrorSnack(context, 'الرابط غير صالح.');
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showErrorSnack(context, 'تعذر فتح الرابط.');
    }
  } catch (exception) {
    if (context.mounted) {
      showErrorSnack(context, 'تعذر فتح الرابط: $exception');
    }
  }
}

Future<void> copyTeacherWhatsApp(BuildContext context) async {
  await Clipboard.setData(
    const ClipboardData(text: teacherWhatsAppNumber),
  );
  if (context.mounted) {
    showSuccess(context, 'تم نسخ رقم واتساب: $teacherWhatsAppNumber');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupApp());
}

class StartupApp extends StatelessWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return NotConfiguredApp(error: snapshot.error.toString());
        }
        return const MathTeacherApp();
      },
    );
  }
}

class MathTeacherApp extends StatelessWidget {
  const MathTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.cairoTextTheme();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPurple,
      brightness: Brightness.light,
      primary: brandPurple,
      secondary: brandGold,
      surface: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: appBackground,
        textTheme: baseTextTheme.apply(
          bodyColor: const Color(0xFF2A2430),
          displayColor: brandPurpleDark,
        ),
        visualDensity: VisualDensity.standard,
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: brandPurpleDark,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.cairo(
            color: brandPurpleDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: const IconThemeData(color: brandPurpleDark),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shadowColor: const Color(0x183E276A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE9E3EF)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 10,
          shadowColor: const Color(0x333E276A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titleTextStyle: GoogleFonts.cairo(
            color: brandPurpleDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          contentTextStyle: GoogleFonts.cairo(
            color: const Color(0xFF403748),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFCFBFD),
          labelStyle: GoogleFonts.cairo(color: const Color(0xFF6F637A)),
          hintStyle: GoogleFonts.cairo(color: const Color(0xFF9B92A3)),
          prefixIconColor: brandPurple,
          suffixIconColor: brandPurple,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDD5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: brandPurple, width: 1.7),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFC62828)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandPurple,
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: Color(0xFFBFB2CA)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brandPurple,
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandGold,
          foregroundColor: Color(0xFF271745),
          elevation: 4,
          focusElevation: 5,
          hoverElevation: 5,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          elevation: 8,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0x243E276A),
          labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? brandPurple
                  : const Color(0xFF726879),
            ),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0x243E276A),
          selectedIconTheme: const IconThemeData(color: brandPurple),
          unselectedIconTheme: const IconThemeData(color: Color(0xFF786E80)),
          selectedLabelTextStyle: GoogleFonts.cairo(
            color: brandPurple,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelTextStyle: GoogleFonts.cairo(
            color: const Color(0xFF665D6D),
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationDrawerTheme: NavigationDrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0x243E276A),
             indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
              topEnd: Radius.circular(28),
              bottomEnd: Radius.circular(28),
            ),
          ),
          labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.cairo(color: const Color(0xFF352D3B)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: brandPurpleDark,
          contentTextStyle: GoogleFonts.cairo(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE9E3EF),
          thickness: 1,
          space: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: brandPurple,
          linearTrackColor: Color(0xFFECE7F1),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthGate(),
    );
  }
}

class NotConfiguredApp extends StatelessWidget {
  final String error;
  const NotConfiguredApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.settings, size: 56, color: brandPurple),
                        const SizedBox(height: 16),
                        const Text(
                          'تعذر الاتصال بـ Firebase',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(error, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) return const LoginScreen();

        final userEmail = emailKey(user.email);
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }
            if (profileSnapshot.hasError) {
              return ErrorScreen(message: profileSnapshot.error.toString());
            }
            if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
              return PendingActivationScreen(email: userEmail);
            }

            final profile = profileSnapshot.data!.data() ?? <String, dynamic>{};
            final role = (profile['role'] ?? 'Pending').toString();
            final active = profile['active'] == true;

            if (!active || role == 'Pending') {
              return PendingActivationScreen(email: userEmail);
            }
            if (role == 'Teacher' || role == 'Admin') {
              return TeacherShell(profile: profile, email: userEmail);
            }
            return StudentShell(profile: profile, email: userEmail);
          },
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isRegister = false;
  bool loading = false;
  bool hidePassword = true;
  String? error;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final email = emailKey(emailController.text);
      final password = passwordController.text.trim();
      final fullName = fullNameController.text.trim();
      final phone = phoneController.text.trim();

      if (!email.contains('@') || password.length < 6) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'أدخل بريدًا صحيحًا وكلمة مرور لا تقل عن 6 أحرف.',
        );
      }
      if (isRegister && fullName.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-name',
          message: 'أدخل اسم الطالبة قبل إنشاء الحساب.',
        );
      }

      if (isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final userDoc = FirebaseFirestore.instance.collection('users').doc(email);
        final existing = await userDoc.get();
        if (!existing.exists) {
          await userDoc.set({
            'email': email,
            'fullName': fullName,
            'phone': phone,
            'role': 'Pending',
            'active': false,
            'classId': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (exception) {
      if (mounted) {
        setState(() => error = exception.message ?? 'تعذر تسجيل الدخول.');
      }
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF2ECF8), Color(0xFFFFFBF1), Color(0xFFF7F5FA)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const PositionedDirectional(
                top: -70,
                end: -55,
                child: _DecorativeCircle(size: 190, color: Color(0x183E276A)),
              ),
              const PositionedDirectional(
                bottom: -85,
                start: -65,
                child: _DecorativeCircle(size: 230, color: Color(0x1FC9A227)),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BrandHeader(compact: false),
                            const SizedBox(height: 24),
                            Text(
                              isRegister ? 'إنشاء حساب طالبة' : 'مرحبًا بعودتك',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: brandPurpleDark,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isRegister
                                  ? 'أنشئي حسابك، ثم ينتظر تفعيل الأستاذ.'
                                  : 'سجّل الدخول للوصول إلى الدروس والنتائج والحضور.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF746A7B)),
                            ),
                            const SizedBox(height: 20),
                            if (isRegister) ...[
                              TextField(
                                controller: fullNameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'اسم الطالبة',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: hidePassword,
                              textDirection: TextDirection.ltr,
                              onSubmitted: (_) => loading ? null : submit(),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => hidePassword = !hidePassword),
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEEE),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x33C62828)),
                                ),
                                child: Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFFC62828)),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: loading ? null : submit,
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(isRegister ? Icons.person_add_alt : Icons.login),
                              label: Text(isRegister ? 'إنشاء الحساب' : 'دخول'),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => setState(() {
                                        isRegister = !isRegister;
                                        error = null;
                                      }),
                              child: Text(
                                isRegister
                                    ? 'لدي حساب بالفعل'
                                    : 'إنشاء حساب طالبة جديد',
                              ),
                            ),
                            const Divider(height: 24),
                            TextButton.icon(
                              onPressed: () => openTeacherWhatsApp(context),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('التواصل عبر واتساب 0956268336'),
                            ),
                            const Text(
                              'لا توجد كلمات مرور محفوظة داخل التطبيق.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingActivationScreen extends StatelessWidget {
  final String email;
  const PendingActivationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحساب بانتظار التفعيل')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top, size: 64, color: brandPurple),
                    const SizedBox(height: 16),
                    const Text(
                      'حسابك موجود، لكنه لم يُفعّل بعد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(email, textDirection: TextDirection.ltr),
                    const SizedBox(height: 14),
                    const Text(
                      'اطلب من الأستاذ تفعيل الحساب وإضافته إلى المجموعة المناسبة.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => openTeacherWhatsApp(context),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('التواصل عبر واتساب 0956268336'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherShell extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String email;
  const TeacherShell({
    super.key,
    required this.profile,
    required this.email,
  });

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int index = 0;

  static const titles = [
    'لوحة الأستاذ',
    'الطالبات',
    'الدروس',
    'النتائج',
    'الحضور',
    'التنبيهات',
    'الإعدادات',
  ];

  static const railDestinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: Text('الرئيسية'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups_rounded),
      label: Text('الطالبات'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('الدروس'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.assessment_outlined),
      selectedIcon: Icon(Icons.assessment_rounded),
      label: Text('النتائج'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event_available_outlined),
      selectedIcon: Icon(Icons.event_available_rounded),
      label: Text('الحضور'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications_rounded),
      label: Text('التنبيهات'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('الإعدادات'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TeacherDashboardPage(),
      const StudentsPage(),
      const LessonsPage(isTeacher: true, classId: 'ALL'),
      const ResultsPage(isTeacher: true, studentEmail: ''),
      const AttendancePage(isTeacher: true, studentEmail: ''),
      const NotificationsPage(isTeacher: true, classId: 'ALL'),
      SettingsPage(profile: widget.profile, email: widget.email),
    ];

    final pageBody = IndexedStack(index: index, children: pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 940;
        final extendedRail = constraints.maxWidth >= 1180;

        final appBar = AppBar(
          title: Row(
            children: [
              const BrandLogo(size: 36),
              const SizedBox(width: 11),
              Expanded(child: Text(titles[index])),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Tooltip(
                message: (widget.profile['fullName'] ?? 'الأستاذ محمود').toString(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0x183E276A),
                  foregroundColor: brandPurple,
                  child: const Icon(Icons.person_rounded, size: 21),
                ),
              ),
            ),
          ],
        );

        if (useRail) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  extended: extendedRail,
                  minExtendedWidth: 220,
                  labelType: extendedRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: (value) => setState(() => index = value),
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 18),
                    child: extendedRail
                        ? const SizedBox(
                            width: 185,
                            child: BrandHeader(compact: true),
                          )
                        : const BrandLogo(size: 48),
                  ),
                  destinations: railDestinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pageBody),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          drawer: NavigationDrawer(
            selectedIndex: index,
            onDestinationSelected: (value) {
              setState(() => index = value);
              Navigator.of(context).pop();
            },
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(18, 24, 18, 12),
                child: BrandHeader(compact: true),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('الرئيسية'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: Text('الطالبات'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: Text('الدروس'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment_rounded),
                label: Text('النتائج'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available_rounded),
                label: Text('الحضور'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: Text('التنبيهات'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: Text('الإعدادات'),
              ),
            ],
          ),
          body: pageBody,
        );
      },
    );
  }
}

class StudentShell extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String email;
  const StudentShell({
    super.key,
    required this.profile,
    required this.email,
  });

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int index = 0;

  static const titles = [
    'الرئيسية',
    'الدروس',
    'نتائجي',
    'حضوري',
    'التنبيهات',
  ];

  @override
  Widget build(BuildContext context) {
    final classId = (widget.profile['classId'] ?? '').toString();
    final pages = [
      StudentDashboardPage(profile: widget.profile, email: widget.email),
      LessonsPage(isTeacher: false, classId: classId),
      ResultsPage(isTeacher: false, studentEmail: widget.email),
      AttendancePage(isTeacher: false, studentEmail: widget.email),
      NotificationsPage(isTeacher: false, classId: classId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 34),
            const SizedBox(width: 10),
            Expanded(child: Text(titles[index])),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('الإعدادات')),
                  body: SettingsPage(
                    profile: widget.profile,
                    email: widget.email,
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'الدروس',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'نتائجي',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'حضوري',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'التنبيهات',
          ),
        ],
      ),
    );
  }
}

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const WelcomeBanner(
          title: 'مرحبًا أستاذ محمود',
          subtitle: 'متابعة منظمة للدروس والطالبات والإنجاز.',
          icon: Icons.functions,
        ),
        const SizedBox(height: 16),
        Text(
          'نظرة سريعة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: const [
            LiveCountCard(
              collection: 'students',
              label: 'الطالبات',
              icon: Icons.groups_outlined,
            ),
            LiveCountCard(
              collection: 'lessons',
              label: 'الدروس',
              icon: Icons.menu_book_outlined,
            ),
            LiveCountCard(
              collection: 'results',
              label: 'النتائج',
              icon: Icons.assessment_outlined,
            ),
            LiveCountCard(
              collection: 'attendance',
              label: 'سجلات الحضور',
              icon: Icons.event_available_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'أحدث التنبيهات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = [...snapshot.data!.docs]
              ..sort((a, b) => timestampMillis(b.data()['createdAt'])
                  .compareTo(timestampMillis(a.data()['createdAt'])));
            if (docs.isEmpty) {
              return const CompactEmptyCard(message: 'لا توجد تنبيهات بعد.');
            }
            return Column(
              children: docs.take(3).map((doc) {
                final data = doc.data();
                final type = (data['type'] ?? 'Important').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NotificationCompactCard(data: data, type: type),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class StudentDashboardPage extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String email;
  const StudentDashboardPage({
    super.key,
    required this.profile,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final name = (profile['fullName'] ?? 'طالبة').toString();
    final classId = (profile['classId'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WelcomeBanner(
          title: 'أهلًا $name',
          subtitle: '${displayClassName(classId)} • $slogan',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('results')
              .where('studentEmail', isEqualTo: emailKey(email))
              .snapshots(),
          builder: (context, resultSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('studentEmail', isEqualTo: emailKey(email))
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                final resultDocs = resultSnapshot.data?.docs ?? [];
                final attendanceDocs = attendanceSnapshot.data?.docs ?? [];
                var scoreTotal = 0.0;
                var maxTotal = 0.0;
                for (final doc in resultDocs) {
                  final score = readDouble(doc.data()['score']);
                  final maxScore = readDouble(doc.data()['maxScore']);
                  if (score != null && maxScore != null && maxScore > 0) {
                    scoreTotal += score;
                    maxTotal += maxScore;
                  }
                }
                final average = maxTotal > 0 ? scoreTotal / maxTotal : 0.0;
                final present = attendanceDocs
                    .where((doc) => doc.data()['status'] == 'Present')
                    .length;
                final attendanceRate = attendanceDocs.isEmpty
                    ? 0.0
                    : present / attendanceDocs.length;

                return Row(
                  children: [
                    Expanded(
                      child: ProgressMetricCard(
                        label: 'متوسط النتائج',
                        value: average,
                        display: maxTotal > 0
                            ? '${(average * 100).round()}%'
                            : 'لا توجد نتائج',
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProgressMetricCard(
                        label: 'نسبة الحضور',
                        value: attendanceRate,
                        display: attendanceDocs.isNotEmpty
                            ? '${(attendanceRate * 100).round()}%'
                            : 'لا توجد سجلات',
                        icon: Icons.event_available_outlined,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          'أحدث التنبيهات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .where('classId', whereIn: [classId, 'ALL']).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return ErrorBox(message: snapshot.error.toString());
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = [...snapshot.data!.docs]
              ..sort((a, b) => timestampMillis(b.data()['createdAt'])
                  .compareTo(timestampMillis(a.data()['createdAt'])));
            if (docs.isEmpty) {
              return const CompactEmptyCard(message: 'لا توجد تنبيهات حالية.');
            }
            return Column(
              children: docs.take(3).map((doc) {
                final data = doc.data();
                final type = (data['type'] ?? 'Important').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NotificationCompactCard(data: data, type: type),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .orderBy('fullName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorBox(message: snapshot.error.toString());
          if (!snapshot.hasData) return const LoadingBox();
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const EmptyBox(
              icon: Icons.groups_outlined,
              message: 'لا توجد طالبات بعد.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final active = (data['status'] ?? 'Active') == 'Active';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0x183E276A),
                        child: Text(
                          ((data['fullName'] ?? 'ط').toString().trim().isEmpty
                                  ? 'ط'
                                  : (data['fullName'] ?? 'ط').toString().trim()[0])
                              .toUpperCase(),
                          style: const TextStyle(
                            color: brandPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['fullName'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              (data['email'] ?? '').toString(),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                SmallChip(
                                  text: displayClassName(data['classId']?.toString()),
                                  icon: Icons.class_outlined,
                                ),
                                SmallChip(
                                  text: active ? 'نشطة' : 'موقوفة',
                                  icon: active
                                      ? Icons.check_circle_outline
                                      : Icons.pause_circle_outline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'خيارات الطالبة',
                        onSelected: (value) {
                          if (value == 'edit') {
                            showStudentDialog(context, studentDoc: doc);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: MenuRow(icon: Icons.edit_outlined, text: 'تعديل'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStudentDialog(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('إضافة طالبة'),
      ),
    );
  }
}

Future<void> showStudentDialog(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? studentDoc,
}) async {
  final isEditing = studentDoc != null;
  final oldData = studentDoc?.data() ?? <String, dynamic>{};
  final name = TextEditingController(text: (oldData['fullName'] ?? '').toString());
  final email = TextEditingController(text: (oldData['email'] ?? '').toString());
  final phone = TextEditingController(text: (oldData['phone'] ?? '').toString());
  var selectedClassId = (oldData['classId'] ?? 'CLS-001').toString();
  var active = (oldData['status'] ?? 'Active') == 'Active';
  var saving = false;
  String? dialogError;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> save() async {
          final studentEmail = emailKey(email.text);
          if (name.text.trim().isEmpty || !studentEmail.contains('@')) {
            setDialogState(() => dialogError = 'أدخل الاسم والبريد الإلكتروني الصحيح.');
            return;
          }
          setDialogState(() {
            saving = true;
            dialogError = null;
          });
          try {
            final studentId = isEditing
                ? studentDoc.id
                : studentDocumentId(studentEmail);
            final db = FirebaseFirestore.instance;
            final batch = db.batch();
            final userRef = db.collection('users').doc(studentEmail);
            final studentRef = db.collection('students').doc(studentId);
            final commonData = <String, dynamic>{
              'email': studentEmail,
              'fullName': name.text.trim(),
              'phone': phone.text.trim(),
              'classId': selectedClassId,
              'updatedAt': FieldValue.serverTimestamp(),
            };
            batch.set(
              userRef,
              {
                ...commonData,
                'role': 'Student',
                'active': active,
                'studentId': studentId,
              },
              SetOptions(merge: true),
            );
            batch.set(
              studentRef,
              {
                ...commonData,
                'studentId': studentId,
                'status': active ? 'Active' : 'Inactive',
                if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
            await batch.commit();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            if (context.mounted) {
              showSuccess(context, isEditing ? 'تم تعديل بيانات الطالبة.' : 'تمت إضافة الطالبة وتفعيلها.');
            }
          } catch (exception) {
            if (dialogContext.mounted) {
              setDialogState(() {
                saving = false;
                dialogError = 'تعذر حفظ البيانات: $exception';
              });
            }
          }
        }

        return AlertDialog(
          title: Text(isEditing ? 'تعديل بيانات الطالبة' : 'إضافة وتفعيل طالبة'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'اسم الطالبة',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    enabled: !saving && !isEditing,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'المجموعة',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CLS-001', child: Text('مجموعة 27')),
                      DropdownMenuItem(value: 'CLS-002', child: Text('مجموعة 28')),
                    ],
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() => selectedClassId = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    enabled: !saving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف – اختياري',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('الحساب نشط'),
                      value: active,
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => active = value),
                    ),
                  ],
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(dialogError!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
            ),
          ],
        );
      },
    ),
  );

  name.dispose();
  email.dispose();
  phone.dispose();
}

class LessonsPage extends StatelessWidget {
  final bool isTeacher;
  final String classId;
  const LessonsPage({
    super.key,
    required this.isTeacher,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('lessons');
    if (!isTeacher) {
      query = query.where('classId', whereIn: [classId, 'ALL']);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorBox(message: snapshot.error.toString());
          if (!snapshot.hasData) return const LoadingBox();
          final docs = [...snapshot.data!.docs]
            ..removeWhere((doc) => !isTeacher && doc.data()['published'] == false)
            ..sort((a, b) => timestampMillis(b.data()['createdAt'])
                .compareTo(timestampMillis(a.data()['createdAt'])));
          if (docs.isEmpty) {
            return const EmptyBox(
              icon: Icons.menu_book_outlined,
              message: 'لا توجد دروس منشورة بعد.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isTeacher ? 92 : 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final description = (data['description'] ?? '').toString().trim();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FeatureIcon(icon: Icons.menu_book_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['title'] ?? 'درس').toString(),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'الوحدة: ${(data['unit'] ?? 'غير محددة')}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(description),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                SmallChip(
                                  text: displayClassName(data['classId']?.toString()),
                                  icon: Icons.groups_outlined,
                                ),
                                if (data['fileUrl']?.toString().trim().isNotEmpty == true)
                                  const SmallChip(text: 'ملف مرفق', icon: Icons.attach_file),
                                if (data['videoUrl']?.toString().trim().isNotEmpty == true)
                                  const SmallChip(text: 'فيديو', icon: Icons.play_circle_outline),
                              ],
                            ),
                            if (data['fileUrl']?.toString().trim().isNotEmpty == true ||
                                data['videoUrl']?.toString().trim().isNotEmpty == true) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (data['fileUrl']?.toString().trim().isNotEmpty == true)
                                    OutlinedButton.icon(
                                      onPressed: () => openExternalLink(
                                        context,
                                        data['fileUrl'].toString(),
                                      ),
                                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                                      label: const Text('فتح الملف'),
                                    ),
                                  if (data['videoUrl']?.toString().trim().isNotEmpty == true)
                                    OutlinedButton.icon(
                                      onPressed: () => openExternalLink(
                                        context,
                                        data['videoUrl'].toString(),
                                      ),
                                      icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                                      label: const Text('مشاهدة الفيديو'),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isTeacher)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showLessonDialog(context, lessonDoc: doc);
                            } else if (value == 'delete') {
                              deleteDocument(
                                context,
                                reference: doc.reference,
                                title: 'حذف الدرس',
                                message: 'هل تريد حذف درس «${data['title'] ?? 'درس'}»؟',
                                successMessage: 'تم حذف الدرس.',
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: MenuRow(icon: Icons.edit_outlined, text: 'تعديل'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: MenuRow(
                                icon: Icons.delete_outline,
                                text: 'حذف',
                                destructive: true,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => showLessonDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة درس'),
            )
          : null,
    );
  }
}

Future<void> showLessonDialog(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? lessonDoc,
}) async {
  final isEditing = lessonDoc != null;
  final oldData = lessonDoc?.data() ?? <String, dynamic>{};
  final title = TextEditingController(text: (oldData['title'] ?? '').toString());
  final unit = TextEditingController(text: (oldData['unit'] ?? '').toString());
  final description = TextEditingController(text: (oldData['description'] ?? '').toString());
  final fileUrl = TextEditingController(text: (oldData['fileUrl'] ?? '').toString());
  final videoUrl = TextEditingController(text: (oldData['videoUrl'] ?? '').toString());
  var selectedClassId = (oldData['classId'] ?? 'CLS-001').toString();
  var published = oldData['published'] != false;
  var saving = false;
  String? dialogError;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> save() async {
          if (title.text.trim().isEmpty) {
            setDialogState(() => dialogError = 'أدخل عنوان الدرس.');
            return;
          }
          setDialogState(() {
            saving = true;
            dialogError = null;
          });
          try {
            final data = <String, dynamic>{
              'title': title.text.trim(),
              'unit': unit.text.trim(),
              'description': description.text.trim(),
              'classId': selectedClassId,
              'fileUrl': fileUrl.text.trim(),
              'videoUrl': videoUrl.text.trim(),
              'published': published,
              'updatedAt': FieldValue.serverTimestamp(),
            };
            if (isEditing) {
              await lessonDoc.reference.update(data);
            } else {
              data['createdAt'] = FieldValue.serverTimestamp();
              await FirebaseFirestore.instance.collection('lessons').add(data);
            }
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            if (context.mounted) {
              showSuccess(context, isEditing ? 'تم تعديل الدرس.' : 'تمت إضافة الدرس.');
            }
          } catch (exception) {
            if (dialogContext.mounted) {
              setDialogState(() {
                saving = false;
                dialogError = 'تعذر حفظ الدرس: $exception';
              });
            }
          }
        }

        return AlertDialog(
          title: Text(isEditing ? 'تعديل الدرس' : 'إضافة درس'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 470,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الدرس',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unit,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'الوحدة أو البحث',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    enabled: !saving,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'وصف مختصر',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'المجموعة',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CLS-001', child: Text('مجموعة 27')),
                      DropdownMenuItem(value: 'CLS-002', child: Text('مجموعة 28')),
                      DropdownMenuItem(value: 'ALL', child: Text('كل المجموعات')),
                    ],
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() => selectedClassId = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fileUrl,
                    enabled: !saving,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'رابط الملف – اختياري',
                      prefixIcon: Icon(Icons.attach_file),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: videoUrl,
                    enabled: !saving,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'رابط الفيديو – اختياري',
                      prefixIcon: Icon(Icons.play_circle_outline),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('منشور للطالبات'),
                    value: published,
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() => published = value),
                  ),
                  if (dialogError != null)
                    Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
            ),
          ],
        );
      },
    ),
  );

  title.dispose();
  unit.dispose();
  description.dispose();
  fileUrl.dispose();
  videoUrl.dispose();
}

class ResultsPage extends StatelessWidget {
  final bool isTeacher;
  final String studentEmail;
  const ResultsPage({
    super.key,
    required this.isTeacher,
    required this.studentEmail,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('results');
    if (!isTeacher) {
      query = query.where('studentEmail', isEqualTo: emailKey(studentEmail));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorBox(message: snapshot.error.toString());
          if (!snapshot.hasData) return const LoadingBox();
          final docs = [...snapshot.data!.docs]
            ..sort((a, b) => timestampMillis(b.data()['createdAt'])
                .compareTo(timestampMillis(a.data()['createdAt'])));
          if (docs.isEmpty) {
            return const EmptyBox(
              icon: Icons.assessment_outlined,
              message: 'لا توجد نتائج بعد.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isTeacher ? 92 : 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['testTitle'] ?? data['title'] ?? 'اختبار').toString();
              final studentName = (data['studentName'] ?? data['studentEmail'] ?? '').toString();
              final score = readDouble(data['score']);
              final maxScore = readDouble(data['maxScore']);
              final progress = score != null && maxScore != null && maxScore > 0
                  ? (score / maxScore).clamp(0.0, 1.0).toDouble()
                  : 0.0;
              final note = (data['note'] ?? '').toString().trim();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FeatureIcon(icon: Icons.assessment_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                                if (isTeacher)
                                  Text(studentName, style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '${displayNumber(data['score'])} / ${displayNumber(data['maxScore'])}',
                              style: const TextStyle(
                                color: brandPurple,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isTeacher)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showResultDialog(context, resultDoc: doc);
                                } else if (value == 'delete') {
                                  deleteDocument(
                                    context,
                                    reference: doc.reference,
                                    title: 'حذف النتيجة',
                                    message: 'هل تريد حذف نتيجة «$title» للطالبة $studentName؟',
                                    successMessage: 'تم حذف النتيجة.',
                                  );
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: MenuRow(icon: Icons.edit_outlined, text: 'تعديل'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: MenuRow(
                                    icon: Icons.delete_outline,
                                    text: 'حذف',
                                    destructive: true,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFECE7F1),
                          color: progress >= 0.6 ? const Color(0xFF2E7D32) : const Color(0xFFE08A00),
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('ملاحظة: $note'),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => showResultDialog(context),
              icon: const Icon(Icons.add_chart),
              label: const Text('إضافة نتيجة'),
            )
          : null,
    );
  }
}

Future<void> showResultDialog(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? resultDoc,
}) async {
  final isEditing = resultDoc != null;
  final oldData = resultDoc?.data() ?? <String, dynamic>{};

  try {
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .orderBy('fullName')
        .get();
    if (!context.mounted) return;
    if (studentSnapshot.docs.isEmpty) {
      showErrorSnack(context, 'أضف طالبة أولاً قبل تسجيل نتيجة.');
      return;
    }

    final students = <String, Map<String, String>>{};
    for (final doc in studentSnapshot.docs) {
      final data = doc.data();
      final email = emailKey((data['email'] ?? '').toString());
      if (email.isNotEmpty) {
        students[email] = {
          'name': (data['fullName'] ?? email).toString(),
          'class': displayClassName(data['classId']?.toString()),
        };
      }
    }
    if (students.isEmpty) {
      showErrorSnack(context, 'لا توجد طالبة ببريد صالح.');
      return;
    }

    final oldEmail = emailKey((oldData['studentEmail'] ?? '').toString());
    var selectedEmail = students.containsKey(oldEmail) ? oldEmail : students.keys.first;
    final title = TextEditingController(
      text: (oldData['testTitle'] ?? oldData['title'] ?? '').toString(),
    );
    final score = TextEditingController(text: (oldData['score'] ?? '').toString());
    final maxScore = TextEditingController(text: (oldData['maxScore'] ?? '').toString());
    final note = TextEditingController(text: (oldData['note'] ?? '').toString());
    var saving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            final scoreValue = readDouble(score.text);
            final maxValue = readDouble(maxScore.text);
            if (title.text.trim().isEmpty ||
                scoreValue == null ||
                maxValue == null ||
                maxValue <= 0 ||
                scoreValue < 0 ||
                scoreValue > maxValue) {
              setDialogState(() {
                dialogError = 'أدخل عنوانًا ودرجة صحيحة لا تتجاوز الدرجة الكاملة.';
              });
              return;
            }
            setDialogState(() {
              saving = true;
              dialogError = null;
            });
            try {
              final data = <String, dynamic>{
                'studentEmail': selectedEmail,
                'studentName': students[selectedEmail]!['name'],
                'testTitle': title.text.trim(),
                'score': scoreValue,
                'maxScore': maxValue,
                'note': note.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (isEditing) {
                await resultDoc.reference.update(data);
              } else {
                data['createdAt'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance.collection('results').add(data);
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (context.mounted) {
                showSuccess(context, isEditing ? 'تم تعديل النتيجة.' : 'تمت إضافة النتيجة.');
              }
            } catch (exception) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  saving = false;
                  dialogError = 'تعذر حفظ النتيجة: $exception';
                });
              }
            }
          }

          return AlertDialog(
            title: Text(isEditing ? 'تعديل النتيجة' : 'إضافة نتيجة'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedEmail,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الطالبة',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: students.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.value['name']} – ${entry.value['class']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => selectedEmail = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'اسم الاختبار أو المذاكرة',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: score,
                            enabled: !saving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'الدرجة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxScore,
                            enabled: !saving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'الدرجة الكاملة'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: note,
                      enabled: !saving,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة – اختيارية',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(dialogError!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
              ),
            ],
          );
        },
      ),
    );

    title.dispose();
    score.dispose();
    maxScore.dispose();
    note.dispose();
  } catch (exception) {
    if (context.mounted) showErrorSnack(context, 'تعذر فتح نافذة النتائج: $exception');
  }
}

class AttendancePage extends StatelessWidget {
  final bool isTeacher;
  final String studentEmail;
  const AttendancePage({
    super.key,
    required this.isTeacher,
    required this.studentEmail,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('attendance');
    if (!isTeacher) {
      query = query.where('studentEmail', isEqualTo: emailKey(studentEmail));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorBox(message: snapshot.error.toString());
          if (!snapshot.hasData) return const LoadingBox();
          final docs = [...snapshot.data!.docs]
            ..sort((a, b) {
              final aDate = DateTime.tryParse((a.data()['lessonDate'] ?? '').toString());
              final bDate = DateTime.tryParse((b.data()['lessonDate'] ?? '').toString());
              return (bDate?.millisecondsSinceEpoch ?? timestampMillis(b.data()['createdAt']))
                  .compareTo(aDate?.millisecondsSinceEpoch ?? timestampMillis(a.data()['createdAt']));
            });
          if (docs.isEmpty) {
            return const EmptyBox(
              icon: Icons.event_available_outlined,
              message: 'لا توجد سجلات حضور بعد.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isTeacher ? 92 : 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final isPresent = data['status'] == 'Present';
              final name = (data['studentName'] ?? data['studentEmail'] ?? '').toString();
              final date = (data['lessonDate'] ?? 'جلسة').toString();
              final note = (data['note'] ?? '').toString().trim();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      FeatureIcon(
                        icon: isPresent ? Icons.check_rounded : Icons.close_rounded,
                        color: isPresent ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isTeacher)
                              Text(
                                name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            Text(
                              date,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontWeight: isTeacher ? FontWeight.w500 : FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              arabicAttendanceStatus(data['status']?.toString()),
                              style: TextStyle(
                                color: isPresent ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (note.isNotEmpty) Text('ملاحظة: $note'),
                          ],
                        ),
                      ),
                      if (isTeacher)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showAttendanceDialog(context, attendanceDoc: doc);
                            } else if (value == 'delete') {
                              deleteDocument(
                                context,
                                reference: doc.reference,
                                title: 'حذف سجل الحضور',
                                message: 'هل تريد حذف سجل $name بتاريخ $date؟',
                                successMessage: 'تم حذف سجل الحضور.',
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: MenuRow(icon: Icons.edit_outlined, text: 'تعديل'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: MenuRow(
                                icon: Icons.delete_outline,
                                text: 'حذف',
                                destructive: true,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => showAttendanceDialog(context),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('تسجيل حضور'),
            )
          : null,
    );
  }
}

Future<void> showAttendanceDialog(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? attendanceDoc,
}) async {
  final isEditing = attendanceDoc != null;
  final oldData = attendanceDoc?.data() ?? <String, dynamic>{};

  try {
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .orderBy('fullName')
        .get();
    if (!context.mounted) return;
    if (studentSnapshot.docs.isEmpty) {
      showErrorSnack(context, 'أضف طالبة أولاً قبل تسجيل الحضور.');
      return;
    }

    final students = <String, String>{};
    for (final doc in studentSnapshot.docs) {
      final data = doc.data();
      final email = emailKey((data['email'] ?? '').toString());
      if (email.isNotEmpty) {
        students[email] = (data['fullName'] ?? email).toString();
      }
    }
    if (students.isEmpty) {
      showErrorSnack(context, 'لا توجد طالبة ببريد إلكتروني صالح.');
      return;
    }
    final oldEmail = emailKey((oldData['studentEmail'] ?? '').toString());
    var selectedEmail = students.containsKey(oldEmail) ? oldEmail : students.keys.first;
    var selectedStatus = oldData['status'] == 'Absent' ? 'Absent' : 'Present';
    final date = TextEditingController(text: (oldData['lessonDate'] ?? todayIso()).toString());
    final note = TextEditingController(text: (oldData['note'] ?? '').toString());
    var saving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickDate() async {
            final initial = DateTime.tryParse(date.text) ?? DateTime.now();
            final selected = await showDatePicker(
              context: dialogContext,
              initialDate: initial,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (selected != null) {
              setDialogState(() => date.text = selected.toIso8601String().split('T').first);
            }
          }

          Future<void> save() async {
            if (DateTime.tryParse(normalizeDigits(date.text)) == null) {
              setDialogState(() => dialogError = 'اختر تاريخًا صحيحًا.');
              return;
            }
            setDialogState(() {
              saving = true;
              dialogError = null;
            });
            try {
              final data = <String, dynamic>{
                'studentEmail': selectedEmail,
                'studentName': students[selectedEmail],
                'status': selectedStatus,
                'lessonDate': normalizeDigits(date.text),
                'note': note.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (isEditing) {
                await attendanceDoc.reference.update(data);
              } else {
                data['createdAt'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance.collection('attendance').add(data);
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (context.mounted) {
                showSuccess(context, isEditing ? 'تم تعديل سجل الحضور.' : 'تم تسجيل الحضور.');
              }
            } catch (exception) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  saving = false;
                  dialogError = 'تعذر حفظ الحضور: $exception';
                });
              }
            }
          }

          return AlertDialog(
            title: Text(isEditing ? 'تعديل سجل الحضور' : 'تسجيل حضور'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedEmail,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الطالبة',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: students.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => selectedEmail = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: date,
                      enabled: !saving,
                      readOnly: true,
                      onTap: pickDate,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'تاريخ الجلسة',
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        suffixIcon: IconButton(
                          onPressed: saving ? null : pickDate,
                          icon: const Icon(Icons.edit_calendar_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        prefixIcon: Icon(Icons.event_available_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Present', child: Text('حاضرة')),
                        DropdownMenuItem(value: 'Absent', child: Text('غائبة')),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => selectedStatus = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: note,
                      enabled: !saving,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة – اختيارية',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(dialogError!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
              ),
            ],
          );
        },
      ),
    );

    date.dispose();
    note.dispose();
  } catch (exception) {
    if (context.mounted) showErrorSnack(context, 'تعذر فتح نافذة الحضور: $exception');
  }
}

class NotificationsPage extends StatelessWidget {
  final bool isTeacher;
  final String classId;
  const NotificationsPage({
    super.key,
    required this.isTeacher,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('announcements');
    if (!isTeacher) {
      query = query.where('classId', whereIn: [classId, 'ALL']);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorBox(message: snapshot.error.toString());
          if (!snapshot.hasData) return const LoadingBox();
          final docs = [...snapshot.data!.docs]
            ..sort((a, b) => timestampMillis(b.data()['createdAt'])
                .compareTo(timestampMillis(a.data()['createdAt'])));
          if (docs.isEmpty) {
            return const EmptyBox(
              icon: Icons.notifications_outlined,
              message: 'لا توجد تنبيهات بعد.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isTeacher ? 92 : 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final type = (data['type'] ?? 'Important').toString();
              final color = notificationTypeColor(type);
              final title = (data['title'] ?? notificationTypeLabel(type)).toString();
              final body = (data['body'] ?? data['message'] ?? data['content'] ?? '').toString();
              final dueDate = (data['dueDate'] ?? '').toString().trim();

              return Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Container(width: 5, color: color),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FeatureIcon(icon: notificationTypeIcon(type), color: color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          TypeChip(type: type),
                                        ],
                                      ),
                                      if (body.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(body),
                                      ],
                                      const SizedBox(height: 9),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          SmallChip(
                                            text: displayClassName(data['classId']?.toString()),
                                            icon: Icons.groups_outlined,
                                          ),
                                          if (dueDate.isNotEmpty)
                                            SmallChip(
                                              text: dueDate,
                                              icon: Icons.calendar_month_outlined,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isTeacher)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        showNotificationDialog(context, notificationDoc: doc);
                                      } else if (value == 'delete') {
                                        deleteDocument(
                                          context,
                                          reference: doc.reference,
                                          title: 'حذف التنبيه',
                                          message: 'هل تريد حذف التنبيه «$title»؟',
                                          successMessage: 'تم حذف التنبيه.',
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: MenuRow(icon: Icons.edit_outlined, text: 'تعديل'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: MenuRow(
                                          icon: Icons.delete_outline,
                                          text: 'حذف',
                                          destructive: true,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => showNotificationDialog(context),
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('إضافة تنبيه'),
            )
          : null,
    );
  }
}

Future<void> showNotificationDialog(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? notificationDoc,
}) async {
  final isEditing = notificationDoc != null;
  final oldData = notificationDoc?.data() ?? <String, dynamic>{};
  final title = TextEditingController(text: (oldData['title'] ?? '').toString());
  final body = TextEditingController(
    text: (oldData['body'] ?? oldData['message'] ?? oldData['content'] ?? '').toString(),
  );
  final dueDate = TextEditingController(text: (oldData['dueDate'] ?? '').toString());
  var selectedType = (oldData['type'] ?? 'Important').toString();
  if (!['Motivation', 'Quiz', 'Important', 'Homework'].contains(selectedType)) {
    selectedType = 'Important';
  }
  var selectedClassId = (oldData['classId'] ?? 'CLS-001').toString();
  var saving = false;
  String? dialogError;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> pickDate() async {
          final initial = DateTime.tryParse(dueDate.text) ?? DateTime.now();
          final selected = await showDatePicker(
            context: dialogContext,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (selected != null) {
            setDialogState(() => dueDate.text = selected.toIso8601String().split('T').first);
          }
        }

        Future<void> save() async {
          if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
            setDialogState(() => dialogError = 'أدخل عنوان التنبيه ونصه.');
            return;
          }
          setDialogState(() {
            saving = true;
            dialogError = null;
          });
          try {
            final data = <String, dynamic>{
              'title': title.text.trim(),
              'body': body.text.trim(),
              'type': selectedType,
              'classId': selectedClassId,
              'dueDate': dueDate.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            if (isEditing) {
              await notificationDoc.reference.update(data);
            } else {
              data['createdAt'] = FieldValue.serverTimestamp();
              await FirebaseFirestore.instance.collection('announcements').add(data);
            }
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            if (context.mounted) {
              showSuccess(context, isEditing ? 'تم تعديل التنبيه.' : 'تم نشر التنبيه داخل التطبيق.');
            }
          } catch (exception) {
            if (dialogContext.mounted) {
              setDialogState(() {
                saving = false;
                dialogError = 'تعذر حفظ التنبيه: $exception';
              });
            }
          }
        }

        return AlertDialog(
          title: Text(isEditing ? 'تعديل التنبيه' : 'إضافة تنبيه'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 470,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع التنبيه',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Motivation', child: Text('تحفيز')),
                      DropdownMenuItem(value: 'Quiz', child: Text('موعد مذاكرة')),
                      DropdownMenuItem(value: 'Important', child: Text('تنبيه مهم')),
                      DropdownMenuItem(value: 'Homework', child: Text('واجب')),
                    ],
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) setDialogState(() => selectedType = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'عنوان التنبيه',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: body,
                    enabled: !saving,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'نص التنبيه',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'المجموعة',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CLS-001', child: Text('مجموعة 27')),
                      DropdownMenuItem(value: 'CLS-002', child: Text('مجموعة 28')),
                      DropdownMenuItem(value: 'ALL', child: Text('كل المجموعات')),
                    ],
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) setDialogState(() => selectedClassId = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDate,
                    enabled: !saving,
                    readOnly: true,
                    onTap: pickDate,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'الموعد – اختياري',
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dueDate.text.isNotEmpty)
                            IconButton(
                              tooltip: 'حذف الموعد',
                              onPressed: saving
                                  ? null
                                  : () => setDialogState(() => dueDate.clear()),
                              icon: const Icon(Icons.clear),
                            ),
                          IconButton(
                            onPressed: saving ? null : pickDate,
                            icon: const Icon(Icons.edit_calendar_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(dialogError!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(saving ? 'جارٍ الحفظ...' : 'نشر'),
            ),
          ],
        );
      },
    ),
  );

  title.dispose();
  body.dispose();
  dueDate.dispose();
}

class SettingsPage extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String email;
  const SettingsPage({
    super.key,
    required this.profile,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = (profile['role'] ?? '').toString() == 'Student';
    final fullName = (profile['fullName'] ?? 'المستخدم').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const BrandHeader(compact: false),
        const SizedBox(height: 18),
        const SettingsSectionTitle(
          icon: Icons.account_circle_outlined,
          title: 'الحساب',
        ),
        const SizedBox(height: 9),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.person_outline,
                  label: 'الاسم',
                  value: fullName,
                ),
                const Divider(height: 25),
                SettingsRow(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: email,
                  ltr: true,
                ),
                if (isStudent) ...[
                  const Divider(height: 25),
                  SettingsRow(
                    icon: Icons.class_outlined,
                    label: 'المجموعة',
                    value: displayClassName(profile['classId']?.toString()),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SettingsSectionTitle(
          icon: Icons.support_agent_rounded,
          title: 'التواصل مع الأستاذ',
        ),
        const SizedBox(height: 9),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    FeatureIcon(
                      icon: Icons.chat_rounded,
                      color: Color(0xFF1B8F4D),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'واتساب الأستاذ محمود الدياب',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: brandPurpleDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            teacherWhatsAppNumber,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5D5364),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => openTeacherWhatsApp(context),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('فتح المحادثة على واتساب'),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: () => copyTeacherWhatsApp(context),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ الرقم'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SettingsSectionTitle(
          icon: Icons.tune_rounded,
          title: 'التطبيق',
        ),
        const SizedBox(height: 9),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: FeatureIcon(icon: Icons.notifications_none_rounded),
                title: Text(
                  'التنبيهات داخل التطبيق',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'تظهر التنبيهات والواجبات والمواعيد داخل المنصة. ستُضاف الإشعارات الفورية لاحقًا.',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const FeatureIcon(icon: Icons.info_outline_rounded),
                title: const Text(
                  'حول التطبيق',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('منصة تعليمية لمتابعة الدروس والنتائج والحضور.'),
                trailing: const Text(
                  'v$appVersionLabel',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontWeight: FontWeight.w800, color: brandPurple),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC62828),
            side: const BorderSide(color: Color(0x55C62828)),
          ),
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }
}

Future<void> deleteDocument(
  BuildContext context, {
  required DocumentReference<Map<String, dynamic>> reference,
  required String title,
  required String message,
  required String successMessage,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text('$message\nلا يمكن التراجع عن الحذف.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('حذف'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await reference.delete();
    if (context.mounted) showSuccess(context, successMessage);
  } catch (exception) {
    if (context.mounted) showErrorSnack(context, 'تعذر الحذف: $exception');
  }
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const SettingsSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: brandPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: brandPurpleDark,
              ),
        ),
      ],
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x33C9A227), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        logoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(Icons.functions, color: brandGold, size: size * 0.7),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  final bool compact;
  const BrandHeader({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brandPurpleDark, brandPurple],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: compact
          ? const Row(
              children: [
                BrandLogo(size: 48),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأستاذ محمود الدياب',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(slogan, style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            )
          : const Column(
              children: [
                BrandLogo(size: 76),
                SizedBox(height: 12),
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(slogan, style: TextStyle(color: Colors.white70)),
              ],
            ),
    );
  }
}

class WelcomeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const WelcomeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brandPurpleDark, brandPurple],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x243E276A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const BrandLogo(size: 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Icon(icon, color: brandGold, size: 34),
        ],
      ),
    );
  }
}

class LiveCountCard extends StatelessWidget {
  final String collection;
  final String label;
  final IconData icon;
  const LiveCountCard({
    super.key,
    required this.collection,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: brandPurple),
                const Spacer(),
                Text(
                  snapshot.hasData ? '${snapshot.data!.docs.length}' : '…',
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: brandPurpleDark),
                ),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProgressMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final String display;
  final IconData icon;
  const ProgressMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.display,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: brandPurple),
            const SizedBox(height: 10),
            Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                backgroundColor: const Color(0xFFECE7F1),
                color: brandGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const FeatureIcon({super.key, required this.icon, this.color = brandPurple});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class SmallChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const SmallChip({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDF5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: brandPurple),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  final String type;
  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = notificationTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        notificationTypeLabel(type),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class NotificationCompactCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;
  const NotificationCompactCard({
    super.key,
    required this.data,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final color = notificationTypeColor(type);
    final body = (data['body'] ?? data['message'] ?? data['content'] ?? '').toString();
    return Card(
      child: ListTile(
        leading: FeatureIcon(icon: notificationTypeIcon(type), color: color),
        title: Text(
          (data['title'] ?? notificationTypeLabel(type)).toString(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: body.isEmpty ? null : Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: TypeChip(type: type),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltr;
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: brandPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(value, textDirection: ltr ? TextDirection.ltr : TextDirection.rtl),
            ],
          ),
        ),
      ],
    );
  }
}

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool destructive;
  const MenuRow({
    super.key,
    required this.icon,
    required this.text,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : null;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ErrorBox(message: message));
  }
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.red),
            const SizedBox(height: 12),
            const Text('حدث خطأ أثناء تحميل البيانات.'),
            const SizedBox(height: 8),
            SelectableText(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class EmptyBox extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyBox({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: brandPurple.withValues(alpha: 0.45)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class CompactEmptyCard extends StatelessWidget {
  final String message;
  const CompactEmptyCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined, color: brandPurple),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
