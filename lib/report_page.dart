import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEvent;
  String? _description;
  File? _imageFile;
  Position? _position;
  String? _placeName;
  String? _weatherDescription;
  bool _isLoading = false;
  String? _feedbackMsg;
  String? _aiDebugMsg;

  String? _nomeUsuario;
  bool _isPCD = false;

  final List<String> _eventTypes = [
    'Chuva muito forte',
    'Enchente',
    'Deslizamento',
    'Vento forte',
    'Granizo',
    'Outro'
  ];

  static const String openWeatherApiKey = '34aa5fc43604a7049e797bb7f486e191';

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    setState(() {
      _nomeUsuario = doc.data()?['nome'] ?? 'Usuário';
      _isPCD = doc.data()?['isPCD'] ?? false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _getPlaceName(double lat, double lon) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=pt-BR';
      final resp = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'FlutterApp'
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return data['display_name'] ?? null;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getWeatherDescription(double lat, double lon) async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&lang=pt_br&units=metric&appid=$openWeatherApiKey';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return data['weather'][0]['description'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _feedbackMsg = 'Serviço de localização desativado.';
          _isLoading = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _feedbackMsg = 'Permissão de localização negada.';
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _feedbackMsg = 'Permissão de localização permanentemente negada.';
          _isLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final place = await _getPlaceName(pos.latitude, pos.longitude);
      final weather = await _getWeatherDescription(pos.latitude, pos.longitude);
      setState(() {
        _position = pos;
        _placeName = place;
        _weatherDescription = weather;
        _feedbackMsg = null;
      });
    } catch (e) {
      setState(() {
        _feedbackMsg = 'Erro ao obter localização.';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<bool> _validateWithAI() async {
    const String apiKey = 'AIzaSyC9cZE9IW6kpGtfAT2nBdGza9jfwoac0YE';

    if (_imageFile == null || _description == null || _position == null) {
      setState(() {
        _aiDebugMsg = 'Faltam dados para validação.';
      });
      return false;
    }

    // Converta a imagem para base64
    final bytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final prompt = """
      Você é uma IA que valida reportes de eventos climáticos críticos. Analise a imagem, a descrição e o clima/localização abaixo. 
      Se for um evento crítico (chuva forte, enchente, deslizamento, etc), responda apenas "CRITICO".
      Em caso de alerta como Outros, considere crítico se houver risco à vida ou danos significativos. 
      Se não for, responda apenas "NAO CRITICO".

      Descrição: $_description
      Localização: ${_placeName ?? 'Não informado'}
      Clima: ${_weatherDescription ?? 'Não informado'}
      """;

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image,
              }
            }
          ]
        }
      ]
    };

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final aiText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      setState(() {
        _aiDebugMsg = 'Resposta da IA: $aiText';
      });
      final resposta = aiText.trim().toUpperCase();
      return resposta == 'CRITICO' || resposta == 'CRÍTICO';
    } else {
      setState(() {
        _aiDebugMsg = 'Erro na requisição: ${response.statusCode}\n${response.body}';
      });
      return false;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _imageFile == null || _position == null) {
      setState(() {
        _feedbackMsg = 'Preencha todos os campos, envie uma imagem e informe a localização.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _feedbackMsg = null;
      _aiDebugMsg = null;
    });

    bool isCritical = await _validateWithAI();

    if (!isCritical) {
      setState(() {
        _isLoading = false;
        _feedbackMsg =
            'O evento reportado não foi identificado como situação de risco. Caso queira tirar dúvidas sobre o que fazer em caso de risco, acesse o Chatbot.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _feedbackMsg = '$_nomeUsuario, seu reporte foi enviado com sucesso para as autoridades!';
      _selectedEvent = null;
      _description = null;
      _imageFile = null;
      _position = null;
      _placeName = null;
      _weatherDescription = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Reportar Evento Climático'),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de evento',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedEvent,
                  items: _eventTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedEvent = val),
                  validator: (val) => val == null ? 'Selecione o tipo de evento' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: (val) => _description = val,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Descreva o que está acontecendo' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Enviar imagem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imageFile != null
                          ? Image.file(_imageFile!, height: 60, fit: BoxFit.cover)
                          : const Text('Nenhuma imagem'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Usar localização atual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _placeName != null
                          ? Text(
                              _placeName!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const Text('Sem localização'),
                    ),
                  ],
                ),
                if (_weatherDescription != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Clima: $_weatherDescription',
                      style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                if (_aiDebugMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _aiDebugMsg!,
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                if (_feedbackMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          _feedbackMsg!,
                          style: TextStyle(
                            color: _feedbackMsg!.contains('sucesso')
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_feedbackMsg!.contains('sucesso') && _isPCD)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Como pessoa com deficiência, você está na fila de prioridade.',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                if (_feedbackMsg != null && _feedbackMsg!.contains('Chatbot'))
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChatScreen()),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Ir para o Chatbot'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}