import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  bool loading = false;
  String? error;
  List<dynamic> weatherAlerts = [];
  List<dynamic> earthquakeAlerts = [];
  Map<String, dynamic>? forecast;
  List<dynamic> dailyForecast = [];
  LatLng selectedLatLng = LatLng(-15.793889, -47.882778); // Default: Brasília
  String locationName = "Buscando localização...";

  @override
  void initState() {
    super.initState();
    _getLocationAndFetch();
  }

  Future<void> _getLocationAndFetch() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Serviço de localização desativado.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização permanentemente negada.');
      }
      final position = await Geolocator.getCurrentPosition();
      selectedLatLng = LatLng(position.latitude, position.longitude);
      await fetchAll();
    } catch (e) {
      selectedLatLng = LatLng(-15.793889, -47.882778);
      await fetchAll();
    }
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchAlerts(),
      fetchForecast(),
      fetchLocationName(),
    ]);
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

  Future<void> fetchForecast() async {
    forecast = null;
    dailyForecast = [];
    final lat = selectedLatLng.latitude;
    final lon = selectedLatLng.longitude;
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode&forecast_days=5&timezone=auto&language=pt';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          forecast = data['current_weather'];
          dailyForecast = data['daily'] != null ? [for (int i = 0; i < (data['daily']['time'] as List).length; i++) {
            'date': data['daily']['time'][i],
            'max': data['daily']['temperature_2m_max'][i],
            'min': data['daily']['temperature_2m_min'][i],
            'precip': data['daily']['precipitation_sum'][i],
            'code': data['daily']['weathercode'][i],
          }] : [];
        });
      }
    } catch (_) {}
  }

  Future<void> fetchAlerts() async {
    weatherAlerts = [];
    earthquakeAlerts = [];
    final lat = selectedLatLng.latitude;
    final lon = selectedLatLng.longitude;

    final weatherUrl =
        'https://api.open-meteo.com/v1/warnings?latitude=$lat&longitude=$lon&language=pt';

    final earthquakeUrl =
        'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.geojson';

    try {
      final weatherResp = await http.get(Uri.parse(weatherUrl));
      if (weatherResp.statusCode == 200) {
        final data = json.decode(weatherResp.body);
        weatherAlerts = data['warnings'] ?? [];
      }

      final eqResp = await http.get(Uri.parse(earthquakeUrl));
      if (eqResp.statusCode == 200) {
        final data = json.decode(eqResp.body);
        earthquakeAlerts = (data['features'] as List)
            .where((f) {
              final props = f['properties'];
              if (props == null) return false;
              final eqLat = f['geometry']['coordinates'][1];
              final eqLon = f['geometry']['coordinates'][0];
              return _distance(lat, lon, eqLat, eqLon) < 1500;
            })
            .toList();
      }
    } catch (_) {}
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String weatherCodeToStr(int? code) {
    if (code == null) return '';
    if (code == 0) return 'Céu limpo';
    if ([1, 2, 3].contains(code)) return 'Parcialmente nublado';
    if ([45, 48].contains(code)) return 'Névoa';
    if ([51, 53, 55].contains(code)) return 'Garoa';
    if ([61, 63, 65].contains(code)) return 'Chuva';
    if ([71, 73, 75, 77].contains(code)) return 'Neve';
    if ([80, 81, 82].contains(code)) return 'Chuva forte';
    if ([95, 96, 99].contains(code)) return 'Tempestade';
    return 'Tempo desconhecido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: SizedBox(
                          height: 320,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                center: selectedLatLng,
                                zoom: 3.5,
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
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    icon: const Icon(Icons.my_location, color: Colors.blue),
                                    tooltip: 'Usar minha localização',
                                    onPressed: _getLocationAndFetch,
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
                      ),
                      if (forecast != null)
                        Card(
                          color: Colors.blue[50],
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.thermostat, color: Colors.blue),
                            title: Text(
                                'Agora: ${forecast!['temperature']}°C, ${weatherCodeToStr(forecast!['weathercode'])}'),
                            subtitle: Text('Vento: ${forecast!['windspeed']} km/h'),
                          ),
                        ),
                      if (dailyForecast.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 130),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: dailyForecast.length,
                            itemBuilder: (context, index) {
                              final day = dailyForecast[index];
                              return Container(
                                width: 130,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                child: Card(
                                  color: Colors.lightBlue[50],
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            day['date'].toString().substring(5),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            weatherCodeToStr(day['code']),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('${day['min']}°C ~ ${day['max']}°C'),
                                          Text('Precip: ${day['precip']}mm'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alertas Meteorológicos',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (weatherAlerts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Nenhum alerta meteorológico.'),
                                )
                              else
                                ...weatherAlerts.map((alert) => Card(
                                      color: Colors.orange[50],
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        leading: const Icon(Icons.warning, color: Colors.orange),
                                        title: Text(alert['event'] ?? 'Alerta'),
                                        subtitle: Text(alert['description'] ?? ''),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desastres Naturais Recentes (até 1500km)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (earthquakeAlerts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Nenhum desastre natural significativo próximo.'),
                                )
                              else
                                SizedBox(
                                  height: 170, // aumente a altura para evitar overflow
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: earthquakeAlerts.length,
                                    itemBuilder: (context, index) {
                                      final eq = earthquakeAlerts[index];
                                      final props = eq['properties'];
                                      final tipo = 'Terremoto'; // Pode adaptar para outros tipos no futuro
                                      return Card(
                                        color: Colors.red[50],
                                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        child: Container(
                                          width: 220,
                                          padding: const EdgeInsets.all(8),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  tipo,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  props['title'] ?? 'Terremoto',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Magnitude: ${props['mag']}'),
                                                Text('Local: ${props['place']}'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}