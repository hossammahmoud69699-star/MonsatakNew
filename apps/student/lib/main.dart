import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const MonsatakApp(configMissing: true));
    return;
  }
  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    runApp(const MonsatakApp());
  } catch (_) {
    runApp(const MonsatakApp(configMissing: true));
  }
}

class MonsatakApp extends StatelessWidget {
  final bool configMissing;
  const MonsatakApp({super.key, this.configMissing = false});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'منصتك التعليمية',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          scaffoldBackgroundColor: const Color(0xFFF5F7FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF14213D),
            foregroundColor: Colors.white,
          ),
          fontFamily: 'Arial',
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: configMissing ? const SetupPage() : const SessionRouter(),
        ),
      );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.school_rounded, size: 76, color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text('منصتك التعليمية',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(
                'يلزم إعداد SUPABASE_URL وSUPABASE_PUBLISHABLE_KEY في إعدادات بناء التطبيق قبل الاتصال بقاعدة البيانات.',
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
}

class SessionRouter extends StatelessWidget {
  const SessionRouter({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) =>
            Supabase.instance.client.auth.currentSession == null
                ? const AuthPage()
                : const StudentHomePage(),
      );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false, _busy = false, _hide = true;
  String? _error, _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        final result = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (result.session == null && mounted) {
          setState(() => _notice =
              'تم إرسال طلب التسجيل. إذا كان تأكيد البريد مطلوبًا، افتح رسالة التأكيد ثم سجّل الدخول.');
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error =
          'تعذر الاتصال. تحقق من إعدادات Supabase والإنترنت.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CircleAvatar(radius: 40,
                              child: Icon(Icons.school_rounded, size: 45)),
                          const SizedBox(height: 14),
                          const Text('منصتك', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_register ? 'إنشاء حساب طالب' : 'تسجيل دخول الطالب',
                              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 22),
                          if (_register) ...[
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اسمك' : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'اكتب بريدًا صحيحًا' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _hide,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _hide = !_hide),
                                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                            validator: (v) => (v ?? '').length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _InfoBox(text: _error!, error: true),
                          ],
                          if (_notice != null) ...[
                            const SizedBox(height: 12),
                            _InfoBox(text: _notice!),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_busy ? 'جارٍ التنفيذ...' : (_register ? 'إنشاء الحساب' : 'تسجيل الدخول')),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => setState(() {
                              _register = !_register; _error = null; _notice = null;
                            }),
                            child: Text(_register ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حسابًا'),
                          ),
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

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});
  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _tab = 0;
  String _search = '';
  Future<List<Map<String, dynamic>>> _loadCourses() async {
    final rows = await Supabase.instance.client
        .from('courses')
        .select('id, title, description')
        .eq('is_published', true)
        .order('title');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _logout() async => Supabase.instance.client.auth.signOut();

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصتك التعليمية'),
        actions: [IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), tooltip: 'تحديث')],
      ),
      body: IndexedStack(index: _tab, children: [
        _courses(),
        const _PlaceholderPage(
          icon: Icons.play_circle_outline,
          title: 'تعلمي',
          message: 'ستظهر الدورات المسجل بها وتقدمك بعد ربط جداول التسجيلات وتتبع الدروس.',
        ),
        _profile(email),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'الدورات'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'تعلمي'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _courses() => Column(children: [
    Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF14213D), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ابدأ رحلة تعلّمك', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('اكتشف الدورات المتاحة وتعلّم في أي وقت.', style: TextStyle(color: Colors.white)),
      ]),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        decoration: const InputDecoration(hintText: 'ابحث عن دورة...', prefixIcon: Icon(Icons.search)),
        onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
      ),
    ),
    Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _PlaceholderPage(
            icon: Icons.cloud_off_outlined,
            title: 'تعذر تحميل الدورات',
            message: 'تحقق من اتصال الإنترنت وصلاحيات قراءة جدول courses في Supabase، ثم اضغط تحديث.',
            buttonText: 'إعادة المحاولة',
            onPressed: () => setState(() {}),
          );
          final rows = (snapshot.data ?? []).where((c) =>
            (c['title'] ?? '').toString().toLowerCase().contains(_search) ||
            (c['description'] ?? '').toString().toLowerCase().contains(_search)).toList();
          if (rows.isEmpty) return _PlaceholderPage(
            icon: Icons.menu_book_outlined,
            title: _search.isEmpty ? 'لا توجد دورات منشورة' : 'لا توجد نتائج',
            message: _search.isEmpty ? 'ستظهر الدورات هنا عندما ينشرها المسؤول.' : 'جرّب كلمات بحث مختلفة.',
            buttonText: _search.isEmpty ? null : 'مسح البحث',
            onPressed: _search.isEmpty ? null : () => setState(() => _search = ''),
          );
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final c = rows[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: const CircleAvatar(child: Icon(Icons.play_lesson_outlined)),
                    title: Text((c['title'] ?? 'دورة تعليمية').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text((c['description'] ?? 'لا يوجد وصف للدورة.').toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoursePage(course: c))),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  ]);

  Widget _profile(String email) => ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 18),
    const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 44)),
    const SizedBox(height: 14),
    const Text('حساب الطالب', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Card(child: ListTile(leading: const Icon(Icons.email_outlined), title: const Text('البريد الإلكتروني'), subtitle: Text(email))),
    const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('عن منصتك'), subtitle: Text('منصة تعليمية لمتابعة الدورات والتعلّم.'))),
    const SizedBox(height: 18),
    OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
  ]);
}

class CoursePage extends StatelessWidget {
  final Map<String, dynamic> course;
  const CoursePage({super.key, required this.course});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل الدورة')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        height: 150,
        decoration: BoxDecoration(color: const Color(0xFFE0EAFE), borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.menu_book_rounded, size: 76, color: Color(0xFF2563EB)),
      ),
      const SizedBox(height: 22),
      Text((course['title'] ?? 'دورة تعليمية').toString(), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Text((course['description'] ?? 'لا يوجد وصف متاح لهذه الدورة.').toString(), style: const TextStyle(fontSize: 16, height: 1.7)),
      const SizedBox(height: 20),
      const _InfoBox(text: 'هذه صفحة تفاصيل أولية. التسجيل وتشغيل الدروس يحتاجان إلى ربط جداول التسجيلات والفصول والمحاضرات والتحقق من سياسات الوصول في قاعدة البيانات.'),
    ]),
  );
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool error;
  const _InfoBox({required this.text, this.error = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: (error ? Colors.red : Colors.blue).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: error ? Colors.red.shade800 : null)),
  );
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? buttonText;
  final VoidCallback? onPressed;
  const _PlaceholderPage({
    required this.icon, required this.title, required this.message,
    this.buttonText, this.onPressed,
  });
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(28), children: [
    const SizedBox(height: 35),
    Icon(icon, size: 64, color: const Color(0xFF2563EB)),
    const SizedBox(height: 16),
    Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Text(message, textAlign: TextAlign.center),
    if (buttonText != null && onPressed != null) ...[
      const SizedBox(height: 18),
      Center(child: OutlinedButton(onPressed: onPressed, child: Text(buttonText!))),
    ],
  ]);
}
