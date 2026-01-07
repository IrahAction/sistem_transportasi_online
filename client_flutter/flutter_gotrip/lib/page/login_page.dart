import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/api.dart';
import 'dart:html' as html;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String role = "user";
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('role')) {
      final r = args['role'];
      if (r is String && r.isNotEmpty) role = r;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password harus diisi")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      
      final Map<String, dynamic>? result = await Api.login(email, password, role);

      if (result != null && result['success'] == true) {
        final token = result['token'] as String? ?? '';
        final userRole = (result['role'] as String?) ?? role;
        final userId = result["user_id"].toString();

        // Save to browser localStorage only when running on web
        if (kIsWeb) {
          try {
            html.window.localStorage['token'] = token;
            html.window.localStorage['role'] = userRole;
            html.window.localStorage["user_id"] = userId;
          } catch (e) {
            // ignore storage errors in case browser blocks it
            debugPrint('LocalStorage error: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login berhasil sebagai $userRole")),
        );

        // Navigate based on role
        switch (userRole) {
          case "user":
            Navigator.pushReplacementNamed(context, "/user_home");
            break;
          case "driver":
            Navigator.pushReplacementNamed(context, "/driver_home");
            break;
          case "merchant":
            Navigator.pushReplacementNamed(context, "/merchant_home");
            break;
          default:
            Navigator.pushReplacementNamed(context, "/");
        }
      } else {
        final msg = (result != null && result['message'] != null)
            ? result['message'].toString()
            : "Login gagal, cek email/password";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan saat login")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login ($role)")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleLogin,
                    child: const Text("Login"),
                  ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/register',
                  arguments: {'role': role},
                );
              },
              child: const Text("Belum punya akun? Daftar"),
            )
          ],
        ),
      ),
    );
  }
}
