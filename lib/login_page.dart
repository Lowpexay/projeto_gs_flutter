import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/auth_exception.dart';
import 'service/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool isLogin = true;
  String error = '';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String senha = senhaController.text;

                try {
                  if (isLogin) {
                    await auth.login(email, senha);
                  } else {
                    await auth.registrar(email, senha);
                  }
                } on AuthException catch (e) {
                  setState(() {
                    error = e.message;
                  });
                } catch (e) {
                  setState(() {
                    error = 'Erro inesperado. Tente novamente.';
                  });
                }
              },
              child: Text(isLogin ? "Entrar" : "Cadastrar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  error = '';
                });
              },
              child: Text(isLogin
                  ? 'Ainda não tem conta? Cadastre-se'
                  : 'Já tem conta? Faça login'),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
