import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      sendMessage(widget.initialMessage!);
    }
  }

  Map<String, String> extractToneAndText(String aiText) {
    final toneRegExp = RegExp(r'\[TOM:\s*(.*?)\]', caseSensitive: false);
    final match = toneRegExp.firstMatch(aiText);
    String tone = 'neutro';
    String cleanText = aiText;
    if (match != null) {
      tone = match.group(1)?.toLowerCase() ?? 'neutro';
      cleanText = aiText.replaceFirst(toneRegExp, '').trim();
    }
    return {
      'tone': tone,
      'text': cleanText,
    };
  }

  String getBotAvatar(String tone) {
    switch (tone) {
      case 'feliz':
        return 'assets/images/nuvem.png';
      case 'triste':
        return 'assets/images/nuvem.png';
      case 'bravo':
        return 'assets/images/nuvem.png';
      case 'explicando':
        return 'assets/images/nuvem.png';
      case 'neutro':
      default:
        return 'assets/images/nuvem.png';
    }
  }

  List<Map<String, dynamic>> buildHistory(String newText) {
    const String systemPrompt = """
    Você é a NumBia, assistente virtual da Nimbus, especializada apenas em temas de **Segurança de pessoas em relação a alterações climáticas**. Responda **em português brasileiro**.

    📌 **Instruções gerais:**
    - Seja objetivo e amigável, mas direto.
    - Não inicie toda mensagem com saudações como "Olá", "Oi", "Tudo bem?". Apenas a interação inicial.
    - Responda usando frases curtas e simples.
    - Não escreva mais do que o necessário para ser claro.
    - Seu foco é apoiar usuários com informações sobre segurança em relação a mudanças climáticas, como alertas de tempestades, inundações, etc. 
    - Se for necessário, apoie emocionalemente o usuário, mas sempre dentro do contexto.

    🎭 **Tom emocional:**
    - Analise a mensagem do usuário e indique o tom no formato [TOM: feliz, bravo, triste, explicando, neutro] antes da resposta.

    🚫 **Assuntos fora do contexto:**
    - Se o tema não for relacionado à ** Segurança de pessoas em relação a alterações climáticas** , responda apenas:
      "Desculpe, não posso te ajudar com isso. Sobre o que de alterações climáticas você gostaria de saber?"
    """;

    List<Map<String, dynamic>> history = [
      {
        "role": "user",
        "parts": [
          {"text": systemPrompt}
        ]
      }
    ];

    for (var msg in messages.takeLast(6)) {
      history.add({
        "role": msg["sender"] == "user" ? "user" : "model",
        "parts": [
          {"text": msg["text"] ?? ""}
        ]
      });
    }

    history.add({
      "role": "user",
      "parts": [
        {"text": newText}
      ]
    });
    return history;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
      isLoading = true;
    });

    final String apiKey = 'AIzaSyC9cZE9IW6kpGtfAT2nBdGza9jfwoac0YE';
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "contents": buildHistory(text),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final aiText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Sem resposta.';
      final result = extractToneAndText(aiText);
      setState(() {
        messages.add({
          "sender": "ai",
          "text": result['text'] ?? '',
          "tone": result['tone'] ?? 'neutro',
        });
      });
    } else {
      setState(() {
        messages.add({
          "sender": "ai",
          "text": "Erro ao se comunicar com o assistente. 😢",
          "tone": "neutro",
        });
      });
    }

    setState(() {
      isLoading = false;
      _controller.clear();
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Widget buildMessage(Map<String, String> msg) {
    bool isUser = msg['sender'] == "user";
    String? tone = msg['tone'] ?? 'neutro';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.blueGrey[900],
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.blueGrey[900] : Colors.orange[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(0) : const Radius.circular(18),
                  bottomRight: isUser ? const Radius.circular(18) : const Radius.circular(0),
                ),
              ),
              child: Text(
                msg['text'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.blueGrey[900],
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.orange,
                backgroundImage: AssetImage(getBotAvatar(tone)),
                radius: 20,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) => buildMessage(messages[index]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.blueGrey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !isLoading,
                      style: TextStyle(color: Colors.blueGrey[900]),
                      decoration: InputDecoration(
                        hintText: isLoading ? "Aguarde a resposta..." : "Digite sua mensagem...",
                        hintStyle: TextStyle(color: Colors.blueGrey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => sendMessage(_controller.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => sendMessage(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Extensão para pegar as últimas N mensagens
extension TakeLastExtension<E> on List<E> {
  Iterable<E> takeLast(int n) => skip(length - n < 0 ? 0 : length - n);
}