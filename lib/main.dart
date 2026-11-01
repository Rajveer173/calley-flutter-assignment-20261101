import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

const primary = Color(0xff5258ed);
const demoMode = bool.fromEnvironment('DEMO_MODE');
void main() => runApp(CalleyApp(api: CalleyApi(demo: demoMode)));

class CalleyApp extends StatelessWidget {
  final CalleyApi api;
  const CalleyApp({super.key, required this.api});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Calley',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff7f8fa),
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    builder: (context, child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
    home: LanguagePage(api: api),
  );
}

void go(BuildContext c, Widget page, {bool replace = false}) {
  final route = MaterialPageRoute<void>(builder: (_) => page);
  if (replace) {
    Navigator.of(c).pushReplacement(route);
  } else {
    Navigator.of(c).push(route);
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 30),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_calling_3_rounded, color: primary, size: 38),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CALLEY',
              style: TextStyle(
                fontSize: 28,
                letterSpacing: 3,
                fontWeight: FontWeight.w300,
                color: primary,
              ),
            ),
            Text(
              'AUTOMATIC CALL DIALER',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class LanguagePage extends StatelessWidget {
  final CalleyApi api;
  const LanguagePage({super.key, required this.api});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Choose Your Language', style: TextStyle(fontSize: 19)),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                child: ListView(
                  children: [
                    const ListTile(
                      title: Text('English'),
                      subtitle: Text('Hi'),
                      trailing: Icon(
                        Icons.radio_button_checked,
                        color: primary,
                      ),
                    ),
                    ...[
                      'Hindi · नमस्ते',
                      'Bengali · নমস্কার',
                      'Kannada · ನಮಸ್ಕಾರ',
                      'Punjabi · ਸਤ ਸ੍ਰੀ ਅਕਾਲ',
                      'Tamil · வணக்கம்',
                      'Telugu · నమస్కారం',
                      'French · Bonjour',
                      'Spanish · Hola',
                    ].map(
                      (s) => ListTile(
                        enabled: false,
                        title: Text(s),
                        trailing: const Icon(Icons.radio_button_off),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'English is available for this version.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () => go(c, AuthPage(api: api), replace: true),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthPage extends StatefulWidget {
  final CalleyApi api;
  final bool login;
  const AuthPage({super.key, required this.api, this.login = false});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      phone = TextEditingController();
  bool busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final address = email.text.trim();
      if (!widget.login) {
        await widget.api.register(name.text.trim(), address, password.text);
      }
      final user = await widget.api.login(address, password.text);
      password.clear();
      if (widget.login) {
        if (mounted) {
          go(context, WelcomePage(api: widget.api, user: user), replace: true);
        }
      } else {
        await widget.api.sendOtp(address);
        if (mounted) {
          go(context, OtpPage(api: widget.api, user: user), replace: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Brand(),
          if (widget.api.demo)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('DEMO MODE · sample data, no emails sent'),
              ),
            ),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: form,
                child: Column(
                  children: [
                    Text(
                      widget.login ? 'Welcome back' : 'Welcome!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.login
                          ? 'Please sign in to continue'
                          : 'Please register to continue',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 28),
                    if (!widget.login) ...[
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          suffixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (s) => s == null || s.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        suffixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (s) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(s?.trim() ?? '')
                          ? null
                          : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (s) =>
                          (s?.isEmpty ?? true) ? 'Enter a password' : null,
                    ),
                    if (!widget.login) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number (optional)',
                          prefixText: '+91 ',
                          suffixIcon: Icon(Icons.phone_android),
                        ),
                        validator: (s) =>
                            s == null ||
                                s.isEmpty ||
                                RegExp(r'^\d{10}$').hasMatch(s)
                            ? null
                            : 'Enter a 10-digit number',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Verification is sent to your email. Mobile number is not sent to the test API.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(
                        busy
                            ? 'Please wait…'
                            : widget.login
                            ? 'Sign In'
                            : 'Sign Up',
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => go(
                              c,
                              AuthPage(api: widget.api, login: !widget.login),
                              replace: true,
                            ),
                      child: Text(
                        widget.login
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class OtpPage extends StatefulWidget {
  final CalleyApi api;
  final User user;
  const OtpPage({super.key, required this.api, required this.user});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final code = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> act({bool resend = false}) async {
    FocusScope.of(context).unfocus();
    if (!resend && !RegExp(r'^\d{6}$').hasMatch(code.text.trim())) {
      setState(() => error = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (resend) {
        await widget.api.sendOtp(widget.user.email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A new code was sent to your email.')),
          );
        }
      } else {
        await widget.api.verifyOtp(widget.user.email, code.text.trim());
        if (mounted) {
          go(
            context,
            WelcomePage(api: widget.api, user: widget.user),
            replace: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(26),
        children: [
          const Brand(),
          const SizedBox(height: 40),
          const Icon(Icons.mark_email_read_outlined, size: 64, color: primary),
          const SizedBox(height: 24),
          const Text(
            'OTP Verification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'Enter the code sent to\n${widget.user.email}',
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.api.demo)
            const Text('Demo code: 123456', textAlign: TextAlign.center),
          TextField(
            controller: code,
            maxLength: 6,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Verification code'),
            style: const TextStyle(letterSpacing: 12, fontSize: 26),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: busy ? null : () => act(),
            child: Text(busy ? 'Please wait…' : 'Verify'),
          ),
          TextButton(
            onPressed: busy ? null : () => act(resend: true),
            child: const Text('Resend OTP'),
          ),
        ],
      ),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  final CalleyApi api;
  final User user;
  const WelcomePage({super.key, required this.api, required this.user});
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: ListView(
          children: [
            const Brand(),
            ProfileCard(user: user, subtitle: 'Calley Personal'),
            const SizedBox(height: 24),
            const Text(
              'Your next conversation\nstarts here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            const Text(
              'Upload your calling list on the Calley web panel, then manage your calls right here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 230,
              child: InkWell(
                onTap: () =>
                    openLink(c, 'https://www.youtube.com/watch?v=bP4U-L4EHcg'),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffe9eaff),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        size: 80,
                        color: primary,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'The 2 minute challenge',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('Watch how it works'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () =>
                  go(c, Dashboard(api: api, user: user), replace: true),
              child: const Text('Start Calling Now'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> openLink(BuildContext c, String url) async {
  try {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception();
    }
  } catch (_) {
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }
}

class ProfileCard extends StatelessWidget {
  final User user;
  final String subtitle;
  const ProfileCard({super.key, required this.user, required this.subtitle});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: primary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xffffd988),
          child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello ${user.name}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class Dashboard extends StatefulWidget {
  final CalleyApi api;
  final User user;
  const Dashboard({super.key, required this.api, required this.user});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  CallSummary? summary;
  CallList? selected;
  bool loading = false;
  String? error;
  Future<void> chooseList() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final lists = await widget.api.lists(widget.user.id);
      if (!mounted) {
        return;
      }
      final item = await showModalBottomSheet<CallList>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CALLING LISTS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                if (lists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No calling lists yet. Add one on the Calley web panel.',
                    ),
                  ),
                ...lists.map(
                  (l) => ListTile(
                    title: Text(l.name),
                    leading: const Icon(Icons.list_alt_rounded, color: primary),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(c, l),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (item != null) {
        final data = await widget.api.details(item.id);
        if (mounted) {
          setState(() {
            selected = item;
            summary = data;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard', style: TextStyle(fontSize: 20)),
      actions: [
        IconButton(
          tooltip: 'Help',
          onPressed: () => openLink(c, 'https://www.getcalley.com/'),
          icon: const Icon(Icons.headset_mic_outlined),
        ),
        IconButton(
          tooltip: 'Refresh calling lists',
          onPressed: loading ? null : chooseList,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ProfileCard(
                user: widget.user,
                subtitle: 'Calley Personal',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
              child: Text(widget.user.email),
            ),
            ...[
              (Icons.rocket_launch_outlined, 'Getting Started'),
              (Icons.sync, 'Sync Data'),
              (Icons.settings_outlined, 'Settings'),
              (Icons.help_outline, 'Help'),
            ].map(
              (entry) => ListTile(
                leading: Icon(entry.$1),
                title: Text(entry.$2),
                onTap: () {
                  Navigator.pop(c);
                  if (entry.$2 == 'Sync Data') {
                    chooseList();
                  } else {
                    showDialog<void>(
                      context: c,
                      builder: (d) => AlertDialog(
                        title: Text(entry.$2),
                        content: Text(
                          entry.$2 == 'Settings'
                              ? 'Language: English\nApp version: 1.0.0\nSession is kept in memory only.'
                              : 'Manage lists at app.getcalley.com. Select a list to view pending, called and scheduled calls.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () => openLink(c, 'https://www.getcalley.com/'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                widget.api.logout();
                Navigator.of(c).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthPage(api: widget.api, login: true),
                  ),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                if (widget.api.demo)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'DEMO MODE · sample data',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                if (summary == null) ...[
                  ProfileCard(
                    user: widget.user,
                    subtitle: 'Welcome to Calley!',
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xff292d65),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'LOAD NUMBER TO CALL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Text(
                            'Ready for a productive day?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Visit app.getcalley.com to upload numbers that you wish to call using Calley Mobile App.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          const Icon(
                            Icons.phone_in_talk_rounded,
                            size: 100,
                            color: primary,
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () =>
                                openLink(c, 'https://app.getcalley.com/'),
                            child: const Text('Open web panel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(selected!.name),
                      subtitle: Text('${summary!.total} CALLS'),
                      trailing: const CircleAvatar(
                        backgroundColor: primary,
                        child: Icon(Icons.list_alt, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    label:
                        '${summary!.pending} pending, ${summary!.called} done, ${summary!.scheduled} scheduled calls',
                    child: SizedBox(
                      height: 240,
                      child: CustomPaint(
                        painter: DonutPainter(summary!),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${summary!.total}',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                'Total calls',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      stat(
                        'Pending',
                        summary!.pending,
                        const Color(0xfff4b53f),
                      ),
                      const SizedBox(width: 8),
                      stat('Done', summary!.called, primary),
                      const SizedBox(width: 8),
                      stat(
                        'Scheduled',
                        summary!.scheduled,
                        const Color(0xffa456eb),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Calls in this list',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  ...summary!.calls.map(
                    (call) => Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: primary,
                        ),
                        title: Text(call.name),
                        subtitle: Text(call.status),
                      ),
                    ),
                  ),
                ],
                if (error != null)
                  Card(
                    color: const Color(0xffffeded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton(
                            onPressed: chooseList,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: FilledButton(
              onPressed: loading ? null : chooseList,
              child: Text(
                loading
                    ? 'Loading…'
                    : summary == null
                    ? 'Start Calling Now'
                    : 'Select Calling List',
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        if (i == 0) {
          setState(() {
            summary = null;
            selected = null;
          });
        } else if (i == 1) {
          chooseList();
        } else {
          openLink(c, 'https://www.youtube.com/watch?v=bP4U-L4EHcg');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.list_alt), label: 'Lists'),
        NavigationDestination(
          icon: Icon(Icons.play_circle_outline),
          label: 'Tutorial',
        ),
      ],
    ),
  );
  Widget stat(String title, int value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11)),
          Text(
            '$value',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const Text('Calls', style: TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

class DonutPainter extends CustomPainter {
  final CallSummary data;
  DonutPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: math.min(size.width, size.height) / 2 - 24,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      paint..color = const Color(0xffe9eaf0),
    );
    if (data.total == 0) {
      return;
    }
    double angle = -math.pi / 2;
    for (final entry in [
      (data.called, primary),
      (data.scheduled, const Color(0xffa456eb)),
      (data.pending, const Color(0xfff4b53f)),
    ]) {
      final sweep = entry.$1 / data.total * 2 * math.pi;
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          angle + .025,
          math.max(0.0, sweep - .05),
          false,
          paint..color = entry.$2,
        );
      }
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.data != data;
}
