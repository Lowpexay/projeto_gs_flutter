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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF9900), Color(0xFFFFB84D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/nuvem.png',
                    height: 70,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Bem-vindo de Volta!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isLogin) ...[
                    _buildTextField("Nome", nomeController),
                    const SizedBox(height: 10),
                    _buildTextField("Sobrenome", sobrenomeController),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text("Pessoa com deficiência (PCD)"),
                      value: isPCD,
                      onChanged: (v) => setState(() => isPCD = v),
                      activeColor: Colors.orange,
                    ),
                  ],
                  _buildTextField("Email", emailController),
                  const SizedBox(height: 10),
                  _buildTextField("Senha", senhaController, obscure: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color.fromARGB(255, 255, 152, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
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
                        } catch (_) {
                          setState(() {
                            error = 'Erro inesperado. Tente novamente.';
                          });
                        }
                      },
                      child: Text(
                        isLogin ? "Login" : "Cadastrar",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                        error = '';
                      });
                    },
                    child: Text(
                      isLogin
                          ? 'Novo por aqui? Cadastre-se'
                          : 'Já tem conta? Faça login',
                      style: const TextStyle(
                        color: Color(0xFF1E1E2C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFFDF6E3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}