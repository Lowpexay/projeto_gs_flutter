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
  final nomeController = TextEditingController();
  final sobrenomeController = TextEditingController();
  bool isPCD = false;

  bool isLogin = true;
  String error = '';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (!isLogin) ...[
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: sobrenomeController,
                decoration: const InputDecoration(labelText: 'Sobrenome'),
              ),
              SwitchListTile(
                title: const Text('Pessoa com deficiência (PCD)'),
                value: isPCD,
                onChanged: (v) => setState(() => isPCD = v),
              ),
            ],
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
                    String nome = nomeController.text;
                    String sobrenome = sobrenomeController.text;
                    await auth.registrar(email, senha, nome, sobrenome, isPCD);
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