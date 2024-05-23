import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Usage Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/aquatracklogo.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: MenuPage(),
          ),
        ),
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Registrar Actividad'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterActivityPage()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Ver Historial'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterActivityPage extends StatefulWidget {
  @override
  _RegisterActivityPageState createState() => _RegisterActivityPageState();
}

class _RegisterActivityPageState extends State<RegisterActivityPage> {
  int _personaId = 1; 
  double _tiempoActividad = 0;

  String _selectedActivity = '';
  List<String> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    var url = Uri.parse('http://localhost:8080/activities');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var activitiesJson = jsonDecode(response.body);
      setState(() {
        _activities = List<String>.from(activitiesJson.map((activity) => activity['nombre_actividad']));
        _selectedActivity = _activities.isNotEmpty ? _activities[0] : '';
      });
    } else {
      print('Failed to fetch activities. Error code: ${response.statusCode}');
    }
  }

  void _registerActivity() async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'persona_id': _personaId,
        'actividad_id': _getActivityId(_selectedActivity),
        'tiempo_actividad': _tiempoActividad,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Actividad registrada con éxito')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar la actividad')));
    }
  }

  int _getActivityId(String activity) {
    switch (activity) {
      case 'Lavar los trastes':
        return 1;
      case 'Ducharse':
        return 2;
      case 'Lavar ropa':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Actividad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButton<String>(
              value: _selectedActivity,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedActivity = newValue!;
                });
              },
              items: _activities.isNotEmpty ? _activities.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList() : [],
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Tiempo (minutos)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _tiempoActividad = double.parse(value);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Registrar'),
              onPressed: _registerActivity,
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    var url = Uri.parse('http://localhost:8080/history');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _history = jsonDecode(response.body);
      });
    } else {
      print('Failed to fetch history. Error code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Actividades'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _history.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  var item = _history[index];
                  return ListTile(
                    title: Text('Actividad ID: ${item['actividad_id']}'),
                    subtitle: Text('Tiempo: ${item['tiempo_actividad']} min\nAgua Gastada: ${item['aprox_agua_gastada']} litros'),
                  );
                },
              ),
      ),
    );
  }
}