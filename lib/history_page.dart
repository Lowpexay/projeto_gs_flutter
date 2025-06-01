import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  LatLng selectedLatLng = LatLng(-15.793889, -47.882778); // Default: Brasília
  String locationName = "Buscando localização...";
  bool loading = false;
  String? errorMsg;
  List<Map<String, dynamic>> history = [];

  // Tier lists
  List<Map<String, dynamic>> tierChuva = [];
  List<Map<String, dynamic>> tierCalor = [];
  List<Map<String, dynamic>> tierFrio = [];

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() {
      loading = true;
      errorMsg = null;
      history = [];
    });
    try {
      await Future.wait([
        fetchLocationName(),
        fetchHistory(),
        fetchTierList(),
      ]);
    } catch (e) {
      setState(() {
        errorMsg = 'Erro ao acessar a API. Tente novamente mais tarde.';
      });
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> fetchLocationName() async {
    final lat = selectedLatLng.latitude;
    final lon = selectedLatLng.longitude;
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=pt-BR';
    try {
      final resp = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'FlutterApp'
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          locationName = data['display_name'] ?? 'Localização desconhecida';
        });
      } else {
        setState(() {
          locationName = 'Localização desconhecida';
        });
      }
    } catch (e) {
      setState(() {
        locationName = 'Localização desconhecida';
      });
    }
  }

  Future<void> fetchHistory() async {
    history = [];
    final lat = selectedLatLng.latitude;
    final lon = selectedLatLng.longitude;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final url =
        'https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=${start.toIso8601String().substring(0,10)}&end_date=${now.toIso8601String().substring(0,10)}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode&timezone=auto&language=pt';

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final daily = data['daily'];
        if (daily != null) {
          for (int i = 0; i < (daily['time'] as List).length; i++) {
            final precip = daily['precipitation_sum'][i];
            final max = daily['temperature_2m_max'][i];
            final min = daily['temperature_2m_min'][i];
            final code = daily['weathercode'][i];
            String? event;
            if (precip != null && precip >= 30) {
              event = 'Chuva forte (${precip}mm)';
            } else if (max != null && max >= 35) {
              event = 'Calor extremo (${max}°C)';
            } else if (min != null && min <= 5) {
              event = 'Frio intenso (${min}°C)';
            } else if ([95, 96, 99].contains(code)) {
              event = 'Tempestade';
            }
            if (event != null) {
              history.add({
                'date': daily['time'][i],
                'event': event,
                'max': max,
                'min': min,
                'precip': precip,
                'code': code,
              });
            }
          }
        }
      } else {
        setState(() {
          errorMsg = 'Erro ao acessar a API de histórico.';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Erro ao acessar a API de histórico.';
      });
    }
  }

  Future<void> fetchTierList() async {
    tierChuva = [];
    tierCalor = [];
    tierFrio = [];
    final lat = selectedLatLng.latitude;
    final lon = selectedLatLng.longitude;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 730)); // 2 anos
    final url =
        'https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=${start.toIso8601String().substring(0,10)}&end_date=${now.toIso8601String().substring(0,10)}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto';

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final daily = data['daily'];
        if (daily != null) {
          List<Map<String, dynamic>> chuva = [];
          List<Map<String, dynamic>> calor = [];
          List<Map<String, dynamic>> frio = [];
          for (int i = 0; i < (daily['time'] as List).length; i++) {
            final precip = daily['precipitation_sum'][i];
            final max = daily['temperature_2m_max'][i];
            final min = daily['temperature_2m_min'][i];
            final date = daily['time'][i];
            if (precip != null) {
              chuva.add({'date': date, 'precip': precip});
            }
            if (max != null) {
              calor.add({'date': date, 'max': max});
            }
            if (min != null) {
              frio.add({'date': date, 'min': min});
            }
          }
          chuva.sort((a, b) => (b['precip'] as num).compareTo(a['precip'] as num));
          calor.sort((a, b) => (b['max'] as num).compareTo(a['max'] as num));
          frio.sort((a, b) => (a['min'] as num).compareTo(b['min'] as num));
          tierChuva = chuva.take(10).toList();
          tierCalor = calor.take(10).toList();
          tierFrio = frio.take(10).toList();
        }
      } else {
        setState(() {
          errorMsg = 'Erro ao acessar a API de tier list.';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Erro ao acessar a API de tier list.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Mapa fixo no topo
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: FlutterMap(
                          options: MapOptions(
                            center: selectedLatLng,
                            zoom: 4,
                            onTap: (tapPosition, point) async {
                              setState(() {
                                selectedLatLng = point;
                                locationName = "Buscando localização...";
                              });
                              await fetchAll();
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 40,
                                  height: 40,
                                  point: selectedLatLng,
                                  rotate: false,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Localização e botão atualizar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          locationName.length > 70
                              ? locationName.substring(0, 70) + '...'
                              : locationName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lat: ${selectedLatLng.latitude.toStringAsFixed(2)}, '
                              'Lon: ${selectedLatLng.longitude.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.blue),
                              tooltip: 'Atualizar',
                              onPressed: fetchAll,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Histórico em lista expandida
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Histórico de Eventos Climáticos (últimos 30 dias)',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                history.isEmpty
                                    ? const Center(
                                        child: Text('Nenhum evento climático extremo registrado.'),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: history.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final event = history[index];
                                          return ListTile(
                                            leading: const Icon(Icons.history, color: Colors.blue),
                                            title: Text(event['event']),
                                            subtitle: Text(
                                                'Data: ${event['date']} | Máx: ${event['max']}°C | Mín: ${event['min']}°C | Precip: ${event['precip']}mm'),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                        // Tier List
                        Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tier List de Eventos Extremos (últimos 2 anos)',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text('Top 10 dias de chuva:'),
                                tierChuva.isEmpty
                                    ? const Text('Sem dados de chuva extrema para este local.')
                                    : Column(
                                        children: tierChuva.map((e) => ListTile(
                                              leading: const Icon(Icons.water_drop, color: Colors.blue),
                                              title: Text('${e['precip']} mm'),
                                              subtitle: Text('Data: ${e['date']}'),
                                            )).toList(),
                                      ),
                                const SizedBox(height: 8),
                                Text('Top 10 dias de calor:'),
                                tierCalor.isEmpty
                                    ? const Text('Sem dados de calor extremo para este local.')
                                    : Column(
                                        children: tierCalor.map((e) => ListTile(
                                              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                                              title: Text('${e['max']}°C'),
                                              subtitle: Text('Data: ${e['date']}'),
                                            )).toList(),
                                      ),
                                const SizedBox(height: 8),
                                Text('Top 10 dias de frio:'),
                                tierFrio.isEmpty
                                    ? const Text('Sem dados de frio extremo para este local.')
                                    : Column(
                                        children: tierFrio.map((e) => ListTile(
                                              leading: const Icon(Icons.ac_unit, color: Colors.lightBlue),
                                              title: Text('${e['min']}°C'),
                                              subtitle: Text('Data: ${e['date']}'),
                                            )).toList(),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}