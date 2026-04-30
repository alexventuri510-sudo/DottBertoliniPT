import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class CreaPianoView extends StatefulWidget {
  final String atletaId;
  final String nomeAtleta;
  final VoidCallback vaiIndietro;

  const CreaPianoView({
    super.key,
    required this.atletaId,
    required this.nomeAtleta,
    required this.vaiIndietro,
  });

  @override
  State<CreaPianoView> createState() => _CreaPianoViewState();
}

class _CreaPianoViewState extends State<CreaPianoView> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _settimaneController = TextEditingController();
  String? _giornoSelezionato;
  String _msgErrore = "";
  bool _isLoading = false;

  final List<String> _giorniSettimana = [
    "Lunedì",
    "Martedì",
    "Mercoledì",
    "Giovedì",
    "Venerdì",
    "Sabato",
    "Domenica",
  ];

  void _aggiornaGiornoAutomatico(String valore) {
    setState(() {
      _msgErrore = "";
      _giornoSelezionato = null;
    });

    if (valore.length == 10) {
      try {
        DateTime dataObj = DateFormat("dd/MM/yyyy").parseStrict(valore);
        setState(() {
          _giornoSelezionato = _giorniSettimana[dataObj.weekday - 1];
          _msgErrore = "";
        });
      } catch (e) {
        setState(() {
          _msgErrore = "Formato data errato";
        });
      }
    } else if (valore.contains("/") && valore.split("/").length == 3) {
      var parti = valore.split("/");
      if (parti[2].length == 4) {
        setState(() => _msgErrore = "Formato data errato");
      }
    }
  }

  Future<void> _salvaPiano() async {
    if (_msgErrore.isNotEmpty) return;

    if (_dataController.text.isEmpty ||
        _settimaneController.text.isEmpty ||
        _giornoSelezionato == null) {
      setState(() => _msgErrore = "Compila tutti i campi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime dataInizio = DateFormat(
        "dd/MM/yyyy",
      ).parseStrict(_dataController.text);
      String dataPerDB = DateFormat("yyyy-MM-dd").format(dataInizio);

      bool success = await DatabaseService.creaPianoAllenamento(
        atletaId: widget.atletaId,
        giornoSettimana: _giornoSelezionato!,
        durataSettimane: int.parse(_settimaneController.text),
        startDate: dataPerDB,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Piano creato con successo!"),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 800), widget.vaiIndietro);
        }
      } else {
        setState(() => _msgErrore = "Errore nel salvataggio!");
      }
    } catch (e) {
      setState(() => _msgErrore = "Errore: controlla i dati inseriti");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.vaiIndietro,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "NUOVO PIANO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Atleta: ${widget.nomeAtleta}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _dataController,
                decoration: const InputDecoration(
                  labelText: "Data Inizio (GG/MM/AAAA)",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                keyboardType: TextInputType.datetime,
                onChanged: _aggiornaGiornoAutomatico,
              ),
              if (_msgErrore.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _msgErrore,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                "Il giorno verrà calcolato automaticamente",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _giornoSelezionato,
                // RIMUOVE IL TRIANGOLO
                icon: const SizedBox.shrink(),
                decoration: const InputDecoration(
                  labelText: "Giorno di allenamento",
                  border: OutlineInputBorder(),
                ),
                items: _giorniSettimana
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: null,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _settimaneController,
                decoration: const InputDecoration(
                  labelText: "Durata (numero settimane)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvaPiano,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CONFERMA E CREA"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
