import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

const brandPurple = Color(0xFF3E276A);
const brandGold = Color(0xFFC9A227);
const appName = 'منصة الأستاذ محمود الدياب';
const slogan = 'نبدأ بالحلم ونصنع الإنجاز';
const logoAsset = 'assets/images/logo.png';

String emailKey(String? email) => (email ?? '').trim().toLowerCase();

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.functions, color: brandGold, size: size);
      },
    );
  }
}

String displayClassName(String? classId) {
  final value = (classId ?? '').trim();
  switch (value) {
    case 'CLS-001':
      return 'مجموعة 27';
    case 'CLS-002':
      return 'مجموعة 28';
    case 'ALL':
      return 'كل المجموعات';
    case '':
      return 'غير محددة';
    default:
      return value;
  }
}

String arabicAttendanceStatus(String? status) {
  return status == 'Present' ? 'حاضرة' : 'غائبة';
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Center(
                  child: Text(
                    'جاري تشغيل التطبيق...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
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
        colorScheme: ColorScheme.fromSeed(seedColor: brandPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: brandPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandGold,
          foregroundColor: Colors.black,
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
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.settings,
                            size: 56, color: brandPurple),
                        const SizedBox(height: 16),
                        const Text(
                          'يلزم ربط التطبيق مع Firebase أولاً',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'افتح مجلد المشروع وشغّل الأمر التالي، ثم أعد تشغيل التطبيق:',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const SelectableText(
                          'flutterfire configure',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
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
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        final key = emailKey(user.email);
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(key)
              .snapshots(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }
            if (!profileSnap.hasData || !profileSnap.data!.exists) {
              return PendingActivationScreen(email: key);
            }

            final data = profileSnap.data!.data() ?? {};
            final role = (data['role'] ?? 'Pending').toString();
            final active = data['active'] == true;
            if (!active || role == 'Pending') {
              return PendingActivationScreen(email: key);
            }
            if (role == 'Teacher' || role == 'Admin') {
              return TeacherShell(profile: data, email: key);
            }
            return StudentShell(profile: data, email: key);
          },
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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

      if (email.isEmpty || password.length < 6) {
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
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(email);
        final snapshot = await userDoc.get();
        if (!snapshot.exists) {
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
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'حدث خطأ في تسجيل الدخول.');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: brandPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          BrandLogo(size: 66),
                          SizedBox(height: 10),
                          Text(
                            appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(slogan, style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      isRegister ? 'إنشاء حساب طالبة' : 'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    if (isRegister) ...[
                      TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الطالبة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (error != null) ...[
                      Text(error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(isRegister ? Icons.person_add : Icons.login),
                      label: Text(isRegister ? 'إنشاء الحساب' : 'دخول'),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => isRegister = !isRegister),
                      child: Text(isRegister
                          ? 'لدي حساب بالفعل'
                          : 'إنشاء حساب طالبة جديد'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخلي الاسم ورقم الهاتف ثم ينتظر الحساب تفعيل الأستاذ. لا توجد كلمات مرور محفوظة داخل التطبيق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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
                  Text('البريد: $email', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text(
                    'اطلب من الأستاذ إضافة بريدك وتفعيلك ضمن الشعبة المناسبة.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
    );
  }
}

class TeacherShell extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String email;
  const TeacherShell({super.key, required this.profile, required this.email});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TeacherDashboardTab(),
      const StudentsTab(),
      const LessonsTab(isTeacher: true, classId: 'ALL'),
      const ResultsTab(isTeacher: true, studentEmail: ''),
      const TeacherAttendanceTab(),
      const AnnouncementsTab(isTeacher: true, classId: 'ALL'),
      const SettingsTab(),
    ];

    final titles = [
      'لوحة الإدارة',
      'الطالبات',
      'الدروس',
      'النتائج',
      'الحضور',
      'الإعلانات',
      'الإعدادات'
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titles[index])),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'الطالبات'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'الدروس'),
          NavigationDestination(
              icon: Icon(Icons.assessment_outlined), label: 'النتائج'),
          NavigationDestination(
              icon: Icon(Icons.event_available_outlined), label: 'الحضور'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined), label: 'إعلانات'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'إعدادات'),
        ],
      ),
    );
  }
}

class StudentShell extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String email;
  const StudentShell({super.key, required this.profile, required this.email});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final classId = (widget.profile['classId'] ?? '').toString();
    final pages = [
      StudentHomeTab(profile: widget.profile, email: widget.email),
      LessonsTab(isTeacher: false, classId: classId),
      ResultsTab(isTeacher: false, studentEmail: widget.email),
      AttendanceTab(studentEmail: widget.email),
      AnnouncementsTab(isTeacher: false, classId: classId),
      const SettingsTab(),
    ];

    final titles = [
      'الرئيسية',
      'الدروس',
      'نتائجي',
      'حضوري',
      'الإعلانات',
      'الإعدادات'
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titles[index])),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'الدروس'),
          NavigationDestination(
              icon: Icon(Icons.assessment_outlined), label: 'نتائجي'),
          NavigationDestination(
              icon: Icon(Icons.event_available_outlined), label: 'حضوري'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined), label: 'إعلانات'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'إعدادات'),
        ],
      ),
    );
  }
}

class TeacherDashboardTab extends StatelessWidget {
  const TeacherDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HeaderCard(
            title: appName, subtitle: slogan, icon: Icons.functions),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snap) => StatCard(
            title: 'عدد الطالبات',
            value: snap.hasData ? '${snap.data!.docs.length}' : '...',
            icon: Icons.groups_outlined,
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
          builder: (context, snap) => StatCard(
            title: 'عدد الدروس',
            value: snap.hasData ? '${snap.data!.docs.length}' : '...',
            icon: Icons.menu_book_outlined,
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('results').snapshots(),
          builder: (context, snap) => StatCard(
            title: 'عدد النتائج',
            value: snap.hasData ? '${snap.data!.docs.length}' : '...',
            icon: Icons.assessment_outlined,
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance.collection('attendance').snapshots(),
          builder: (context, snap) => StatCard(
            title: 'سجلات الحضور',
            value: snap.hasData ? '${snap.data!.docs.length}' : '...',
            icon: Icons.event_available_outlined,
          ),
        ),
      ],
    );
  }
}

class StudentHomeTab extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String email;
  const StudentHomeTab({super.key, required this.profile, required this.email});

  @override
  Widget build(BuildContext context) {
    final name = (profile['fullName'] ?? 'طالبة').toString();
    final classId = (profile['classId'] ?? '').toString();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderCard(
            title: 'أهلاً $name',
            subtitle: slogan,
            icon: Icons.school_outlined),
        const SizedBox(height: 12),
        StatCard(
            title: 'الشعبة',
            value: displayClassName(classId),
            icon: Icons.class_outlined),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('results')
              .where('studentEmail', isEqualTo: email)
              .snapshots(),
          builder: (context, snap) => StatCard(
            title: 'عدد نتائجي',
            value: snap.hasData ? '${snap.data!.docs.length}' : '...',
            icon: Icons.assessment_outlined,
          ),
        ),
      ],
    );
  }
}

class StudentsTab extends StatelessWidget {
  const StudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .orderBy('fullName')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return ErrorBox(message: snap.error.toString());
          if (!snap.hasData) return const LoadingScreen();
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const EmptyBox(message: 'لا توجد طالبات بعد.');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text((data['fullName'] ?? '').toString()),
                  subtitle: Text(
                      '${data['email'] ?? ''}\nالشعبة: ${displayClassName(data['classId']?.toString())}'),
                  isThreeLine: true,
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

Future<void> showStudentDialog(BuildContext context) async {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  String selectedClassId = 'CLS-001';

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('إضافة/تفعيل طالبة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الطالبة')),
              TextField(
                  controller: email,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedClassId,
                decoration: const InputDecoration(labelText: 'المجموعة'),
                items: const [
                  DropdownMenuItem(value: 'CLS-001', child: Text('مجموعة 27')),
                  DropdownMenuItem(value: 'CLS-002', child: Text('مجموعة 28')),
                ],
                onChanged: (value) {
                  if (value != null)
                    setDialogState(() => selectedClassId = value);
                },
              ),
              TextField(
                  controller: phone,
                  decoration:
                      const InputDecoration(labelText: 'رقم الهاتف اختياري')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final studentEmail = emailKey(email.text);
              if (studentEmail.isEmpty || name.text.trim().isEmpty) return;
              final studentId =
                  studentEmail.replaceAll('.', '_').replaceAll('@', '_');
              final db = FirebaseFirestore.instance;
              await db.collection('users').doc(studentEmail).set({
                'email': studentEmail,
                'fullName': name.text.trim(),
                'role': 'Student',
                'active': true,
                'classId': selectedClassId,
                'studentId': studentId,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              await db.collection('students').doc(studentId).set({
                'studentId': studentId,
                'email': studentEmail,
                'fullName': name.text.trim(),
                'classId': selectedClassId,
                'phone': phone.text.trim(),
                'status': 'Active',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  email.dispose();
  phone.dispose();
}

class LessonsTab extends StatelessWidget {
  final bool isTeacher;
  final String classId;
  const LessonsTab({super.key, required this.isTeacher, required this.classId});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('lessons');
    if (!isTeacher) {
      query = query.where('classId', whereIn: [classId, 'ALL']);
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return ErrorBox(message: snap.error.toString());
          if (!snap.hasData) return const LoadingScreen();
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const EmptyBox(message: 'لا توجد دروس منشورة بعد.');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              return Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.menu_book_outlined, color: brandPurple),
                  title: Text((data['title'] ?? '').toString()),
                  subtitle: Text(
                      'الوحدة: ${data['unit'] ?? ''}\nالشعبة: ${displayClassName(data['classId']?.toString())}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => showBasicAddDialog(
                context,
                title: 'إضافة درس',
                collection: 'lessons',
                fields: const [
                  'title',
                  'unit',
                  'classId',
                  'fileUrl',
                  'videoUrl'
                ],
                defaults: const {'classId': 'CLS-001', 'published': true},
              ),
              icon: const Icon(Icons.add),
              label: const Text('درس'),
            )
          : null,
    );
  }
}

class ResultsTab extends StatelessWidget {
  final bool isTeacher;
  final String studentEmail;

  const ResultsTab({
    super.key,
    required this.isTeacher,
    required this.studentEmail,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('results');

    if (!isTeacher) {
      query = query.where(
        'studentEmail',
        isEqualTo: emailKey(studentEmail),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorBox(message: snap.error.toString());
          }

          if (!snap.hasData) {
            return const LoadingScreen();
          }

          final docs = [...snap.data!.docs];

          // ترتيب النتائج من الأحدث إلى الأقدم دون الحاجة إلى Firestore Index.
          docs.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];

            final aMilliseconds =
                aTime is Timestamp ? aTime.millisecondsSinceEpoch : 0;
            final bMilliseconds =
                bTime is Timestamp ? bTime.millisecondsSinceEpoch : 0;

            return bMilliseconds.compareTo(aMilliseconds);
          });

          if (docs.isEmpty) {
            return const EmptyBox(message: 'لا توجد نتائج بعد.');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final resultDoc = docs[index];
              final data = resultDoc.data();

              final testTitle =
                  (data['testTitle'] ?? 'اختبار').toString();
              final score = (data['score'] ?? '').toString();
              final maxScore = (data['maxScore'] ?? '').toString();
              final studentName =
                  (data['studentName'] ?? data['studentEmail'] ?? '')
                      .toString();
              final note = (data['note'] ?? '').toString().trim();

              return Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0x183E276A),
                        child: Icon(
                          Icons.assessment_outlined,
                          color: brandPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testTitle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (studentName.isNotEmpty)
                              Text(
                                studentName,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x143E276A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '$score / $maxScore',
                                  style: const TextStyle(
                                    color: brandPurple,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 9),
                              Text('ملاحظة: $note'),
                            ],
                          ],
                        ),
                      ),
                      if (isTeacher)
                        PopupMenuButton<String>(
                          tooltip: 'خيارات النتيجة',
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await showResultDialog(
                                context,
                                resultDoc: resultDoc,
                              );
                            } else if (value == 'delete') {
                              await deleteResult(
                                context,
                                resultDoc.reference,
                                testTitle,
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 10),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'حذف',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
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
              onPressed: () => showResultDialog(context),
              icon: const Icon(Icons.add_chart),
              label: const Text('نتيجة'),
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
    final studentsSnap = await FirebaseFirestore.instance
        .collection('students')
        .orderBy('fullName')
        .get();

    if (!context.mounted) return;

    if (studentsSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف طالبة أولاً قبل تسجيل نتيجة.'),
        ),
      );
      return;
    }

    // استخدام البريد مفتاحاً يمنع ظهور عناصر Dropdown مكررة.
    final studentNames = <String, String>{};
    final studentLabels = <String, String>{};

    for (final doc in studentsSnap.docs) {
      final data = doc.data();
      final email =
          emailKey((data['email'] ?? doc.id).toString());

      if (email.isEmpty) continue;

      final name = (data['fullName'] ?? email).toString();
      final className =
          displayClassName(data['classId']?.toString());

      studentNames[email] = name;
      studentLabels[email] = '$name - $className';
    }

    if (studentLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد طالبة ببريد إلكتروني صالح.'),
        ),
      );
      return;
    }

    final oldEmail =
        emailKey((oldData['studentEmail'] ?? '').toString());

    String selectedEmail = studentLabels.containsKey(oldEmail)
        ? oldEmail
        : studentLabels.keys.first;

    final testTitle = TextEditingController(
      text: (oldData['testTitle'] ??
              (isEditing ? '' : 'اختبار'))
          .toString(),
    );
    final score = TextEditingController(
      text: (oldData['score'] ?? '').toString(),
    );
    final maxScore = TextEditingController(
      text: (oldData['maxScore'] ??
              (isEditing ? '' : '100'))
          .toString(),
    );
    final note = TextEditingController(
      text: (oldData['note'] ?? '').toString(),
    );

    bool saving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> saveResult() async {
            final titleValue = testTitle.text.trim();
            final scoreValue = num.tryParse(score.text.trim());
            final maxScoreValue =
                num.tryParse(maxScore.text.trim());

            if (titleValue.isEmpty) {
              setDialogState(
                () => dialogError = 'أدخل اسم الاختبار.',
              );
              return;
            }

            if (scoreValue == null || maxScoreValue == null) {
              setDialogState(
                () => dialogError =
                    'أدخل الدرجة والدرجة العظمى كأرقام صحيحة.',
              );
              return;
            }

            if (scoreValue < 0 || maxScoreValue <= 0) {
              setDialogState(
                () => dialogError =
                    'يجب أن تكون الدرجة غير سالبة والدرجة العظمى أكبر من صفر.',
              );
              return;
            }

            if (scoreValue > maxScoreValue) {
              setDialogState(
                () => dialogError =
                    'لا يمكن أن تكون الدرجة أكبر من الدرجة العظمى.',
              );
              return;
            }

            setDialogState(() {
              saving = true;
              dialogError = null;
            });

            final data = <String, dynamic>{
              'studentEmail': emailKey(selectedEmail),
              'studentName':
                  studentNames[selectedEmail] ?? selectedEmail,
              'testTitle': titleValue,
              'score': scoreValue,
              'maxScore': maxScoreValue,
              'note': note.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            };

            try {
              if (isEditing) {
              await resultDoc!.reference.update(data);
              } else {
                data['createdAt'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance
                    .collection('results')
                    .add(data);
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'تم تعديل النتيجة بنجاح.'
                          : 'تمت إضافة النتيجة بنجاح.',
                    ),
                  ),
                );
              }
            } catch (error) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  saving = false;
                  dialogError = 'تعذر حفظ النتيجة: $error';
                });
              }
            }
          }

          return AlertDialog(
            title: Text(
              isEditing ? 'تعديل النتيجة' : 'إضافة نتيجة',
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedEmail,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'اختيار الطالبة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: studentLabels.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(
                                  () => selectedEmail = value,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testTitle,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'اسم الاختبار',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.quiz_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: score,
                      enabled: !saving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الدرجة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grade_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxScore,
                      enabled: !saving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الدرجة العظمى',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: note,
                      enabled: !saving,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: saving ? null : saveResult,
                icon: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isEditing
                            ? Icons.save_outlined
                            : Icons.add_chart,
                      ),
                label: Text(
                  saving
                      ? 'جارٍ الحفظ...'
                      : isEditing
                          ? 'حفظ التعديل'
                          : 'إضافة',
                ),
              ),
            ],
          );
        },
      ),
    );

    testTitle.dispose();
    score.dispose();
    maxScore.dispose();
    note.dispose();
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تعذر فتح نافذة النتيجة: $error'),
      ),
    );
  }
}

Future<void> deleteResult(
  BuildContext context,
  DocumentReference<Map<String, dynamic>> reference,
  String testTitle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف النتيجة'),
      content: Text(
        'هل أنت متأكد من حذف نتيجة «$testTitle»؟\n'
        'لا يمكن التراجع عن الحذف.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('حذف'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await reference.delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف النتيجة بنجاح.'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حذف النتيجة: $error'),
        ),
      );
    }
  }
}

class AttendanceTab extends StatelessWidget {
  final String studentEmail;
  const AttendanceTab({super.key, required this.studentEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentEmail', isEqualTo: studentEmail)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return ErrorBox(message: snap.error.toString());
        if (!snap.hasData) return const LoadingScreen();
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return const EmptyBox(message: 'لا توجد سجلات حضور بعد.');
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final isPresent = data['status'] == 'Present';
            return Card(
              child: ListTile(
                leading: Icon(
                  isPresent
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: isPresent ? Colors.green : Colors.red,
                ),
                title: Text((data['lessonDate'] ?? 'جلسة').toString()),
                subtitle: Text(
                    'الحالة: ${arabicAttendanceStatus(data['status']?.toString())}\n${data['note'] ?? ''}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class TeacherAttendanceTab extends StatelessWidget {
  const TeacherAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return ErrorBox(message: snap.error.toString());
          if (!snap.hasData) return const LoadingScreen();
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const EmptyBox(message: 'لا توجد سجلات حضور بعد.');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final isPresent = data['status'] == 'Present';
              return Card(
                child: ListTile(
                  leading: Icon(
                    isPresent
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                  title: Text(
                      (data['studentName'] ?? data['studentEmail'] ?? '')
                          .toString()),
                  subtitle: Text(
                      '${data['lessonDate'] ?? 'جلسة'}\nالحالة: ${arabicAttendanceStatus(data['status']?.toString())}\n${data['note'] ?? ''}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAttendanceDialog(context),
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('تسجيل حضور'),
      ),
    );
  }
}

Future<void> showAttendanceDialog(BuildContext context) async {
  final studentsSnap = await FirebaseFirestore.instance
      .collection('students')
      .orderBy('fullName')
      .get();
  if (!context.mounted) return;
  if (studentsSnap.docs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف طالبة أولاً قبل تسجيل الحضور.')));
    return;
  }

  String selectedEmail =
      (studentsSnap.docs.first.data()['email'] ?? studentsSnap.docs.first.id)
          .toString();
  String selectedStatus = 'Present';
  final lessonDate = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final note = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('تسجيل حضور'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedEmail,
                decoration: const InputDecoration(labelText: 'اختيار الطالبة'),
                items: studentsSnap.docs.map((doc) {
                  final data = doc.data();
                  final email = (data['email'] ?? doc.id).toString();
                  final name = (data['fullName'] ?? email).toString();
                  final cls = displayClassName(data['classId']?.toString());
                  return DropdownMenuItem(
                      value: email, child: Text('$name - $cls'));
                }).toList(),
                onChanged: (value) {
                  if (value != null)
                    setDialogState(() => selectedEmail = value);
                },
              ),
              TextField(
                  controller: lessonDate,
                  decoration: const InputDecoration(labelText: 'تاريخ الجلسة')),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: 'Present', child: Text('حاضرة')),
                  DropdownMenuItem(value: 'Absent', child: Text('غائبة')),
                ],
                onChanged: (value) {
                  if (value != null)
                    setDialogState(() => selectedStatus = value);
                },
              ),
              TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'ملاحظة')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final selectedIndex = studentsSnap.docs.indexWhere((doc) {
                final data = doc.data();
                final email = (data['email'] ?? doc.id).toString();
                return emailKey(email) == emailKey(selectedEmail);
              });

              if (selectedIndex == -1) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('لم يتم العثور على الطالبة المختارة')),
                  );
                }
                return;
              }

              final selectedDoc = studentsSnap.docs[selectedIndex];
              final selectedData = selectedDoc.data();
              await FirebaseFirestore.instance.collection('attendance').add({
                'studentEmail': emailKey(selectedEmail),
                'studentName': (selectedData['fullName'] ?? '').toString(),
                'status': selectedStatus,
                'lessonDate': lessonDate.text.trim(),
                'note': note.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );

  lessonDate.dispose();
  note.dispose();
}

class AnnouncementsTab extends StatelessWidget {
  final bool isTeacher;
  final String classId;
  const AnnouncementsTab(
      {super.key, required this.isTeacher, required this.classId});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('announcements');
    if (!isTeacher) query = query.where('classId', whereIn: [classId, 'ALL']);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return ErrorBox(message: snap.error.toString());
          if (!snap.hasData) return const LoadingScreen();
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const EmptyBox(message: 'لا توجد إعلانات بعد.');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              return Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.campaign_outlined, color: brandPurple),
                  title: Text((data['title'] ?? '').toString()),
                  subtitle: Text(
                      '${data['body'] ?? ''}\nالشعبة: ${displayClassName(data['classId']?.toString() ?? 'ALL')}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => showBasicAddDialog(
                context,
                title: 'إضافة إعلان',
                collection: 'announcements',
                fields: const ['title', 'body', 'classId'],
                defaults: const {'classId': 'ALL'},
              ),
              icon: const Icon(Icons.add),
              label: const Text('إعلان'),
            )
          : null,
    );
  }
}

Future<void> showBasicAddDialog(
  BuildContext context, {
  required String title,
  required String collection,
  required List<String> fields,
  Map<String, dynamic> defaults = const {},
}) async {
  final controllers = <String, TextEditingController>{
    for (final f in fields)
      f: TextEditingController(text: defaults[f]?.toString() ?? ''),
  };

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: controllers[f],
                    decoration: InputDecoration(labelText: fieldLabel(f)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
          onPressed: () async {
            final data = <String, dynamic>{...defaults};
            for (final f in fields) {
              final value = controllers[f]!.text.trim();
              final number = num.tryParse(value);
              data[f] = number ?? value;
            }
            data['createdAt'] = FieldValue.serverTimestamp();
            if (data.containsKey('studentEmail')) {
              data['studentEmail'] = emailKey(data['studentEmail'].toString());
            }
            await FirebaseFirestore.instance.collection(collection).add(data);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );

  for (final c in controllers.values) {
    c.dispose();
  }
}

String fieldLabel(String field) {
  switch (field) {
    case 'title':
      return 'العنوان';
    case 'body':
      return 'النص';
    case 'unit':
      return 'الوحدة';
    case 'classId':
      return 'المجموعة';
    case 'fileUrl':
      return 'رابط ملف PDF';
    case 'videoUrl':
      return 'رابط الفيديو';
    case 'studentEmail':
      return 'بريد الطالبة';
    case 'testTitle':
      return 'اسم الاختبار';
    case 'score':
      return 'الدرجة';
    case 'maxScore':
      return 'الدرجة العظمى';
    case 'note':
      return 'ملاحظة';
    default:
      return field;
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderCard(
            title: 'الإعدادات',
            subtitle: user?.email ?? '',
            icon: Icons.settings_outlined),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('تسجيل الخروج'),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ),
      ],
    );
  }
}

class HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const HeaderCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [brandPurple, Color(0xFF65409B)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: brandGold,
            child: icon == Icons.functions
                ? const BrandLogo(size: 42)
                : Icon(icon, color: Colors.black, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const StatCard(
      {super.key,
      required this.title,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: brandPurple),
        title: Text(title),
        trailing: Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class EmptyBox extends StatelessWidget {
  final String message;
  const EmptyBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
      ),
    );
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
        child: Text('حدث خطأ:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
