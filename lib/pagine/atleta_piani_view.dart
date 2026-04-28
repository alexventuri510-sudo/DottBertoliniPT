import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class AtletaPianiView extends StatefulWidget {
  final String atletaId;
  final String nomeAtleta;
  final Function(Map<String, dynamic>, String, int) vaiAListaEsercizi;
  final VoidCallback vaiIndietro;

  const AtletaPianiView({
    super.key,
    required this.atletaId,
    required this.nomeAtleta,
    required this.vaiAListaEsercizi,
    required this.vaiIndietro,
  });

  @override
  State<AtletaPianiView> createState() => _AtletaPianiViewState();
}

class _AtletaPianiViewState extends State<AtletaPianiView> {
  List<dynamic> _pianiAttivi = [];
  List<dynamic> _pianiPassati = [];
  List<dynamic> _pianiFuturi = [];
  bool _mostraPassati = false;
  bool _mostraFuturi = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaPiani();
  }

  Future<void> _caricaPiani() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final piani = await DatabaseService.getPianiAtleta(widget.atletaId);

      final oggi = DateTime.now();
      final oggiSoloData = DateTime(oggi.year, oggi.month, oggi.day);

      List<dynamic> attivi = [];
      List<dynamic> passati = [];
      List<dynamic> futuri = [];

      for (var p in piani) {
        if (p['start_date'] == null) continue;

        DateTime dataInizio = DateTime.parse(p['start_date']);
        int settimane = p['duration_weeks'] ?? 1;
        // Calcolo scadenza corretta: (settimane * 7) - 1 giorno
        DateTime dataScadenza = dataInizio.add(
          Duration(days: (settimane * 7) - 1),
        );

        String? testoSettimana;
        int settimanaCorrente = 1;
        String stato;

        if (oggiSoloData.isBefore(dataInizio)) {
          stato = "futuro";
          testoSettimana = "Inizio programmato";
        } else if (oggiSoloData.isAfter(dataScadenza)) {
          stato = "passato";
          testoSettimana = "Completato";
        } else {
          stato = "attivo";
          int giorniPassati = oggiSoloData.difference(dataInizio).inDays;
          settimanaCorrente = (giorniPassati ~/ 7) + 1;
          if (settimanaCorrente > settimane) settimanaCorrente = settimane;
          testoSettimana = "Settimana attuale: $settimanaCorrente";
        }

        var pianoArricchito = {
          ...Map<String, dynamic>.from(p),
          'testoSettimana': testoSettimana,
          'settimanaCorrente': settimanaCorrente,
          'stato': stato,
          'dataInizioFormattata': DateFormat('dd/MM/yyyy').format(dataInizio),
        };

        if (stato == "passato") {
          passati.add(pianoArricchito);
        } else if (stato == "futuro") {
          futuri.add(pianoArricchito);
        } else {
          attivi.add(pianoArricchito);
        }
      }

      const ordineGiorni = {
        "Lunedì": 1,
        "Martedì": 2,
        "Mercoledì": 3,
        "Giovedì": 4,
        "Venerdì": 5,
        "Sabato": 6,
        "Domenica": 7,
      };

      attivi.sort(
        (a, b) => (ordineGiorni[a['day_of_week']] ?? 9).compareTo(
          ordineGiorni[b['day_of_week']] ?? 9,
        ),
      );
      futuri.sort(
        (a, b) => DateTime.parse(
          a['start_date'],
        ).compareTo(DateTime.parse(b['start_date'])),
      );

      if (mounted) {
        setState(() {
          _pianiAttivi = attivi;
          _pianiPassati = passati;
          _pianiFuturi = futuri;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento piani: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: widget.vaiIndietro,
        ),
        title: const Text(
          "I TUOI PIANI",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _caricaPiani,
              color: Colors.black,
              child: ListView(
                padding: const EdgeInsets.all(25),
                children: [
                  _buildSezioneTitolo("PIANI IN CORSO"),
                  const SizedBox(height: 15),
                  if (_pianiAttivi.isEmpty)
                    _buildEmptyMsg("Nessun allenamento disponibile.")
                  else
                    ..._pianiAttivi.map(
                      (p) => _buildCardPiano(Map<String, dynamic>.from(p)),
                    ),

                  // --- SEZIONE PIANI FUTURI ---
                  if (_pianiFuturi.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(thickness: 0.5),
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _mostraFuturi = !_mostraFuturi),
                        icon: Icon(
                          _mostraFuturi ? Icons.keyboard_arrow_up : Icons.event,
                          color: Colors.blueGrey,
                          size: 20,
                        ),
                        label: Text(
                          _mostraFuturi
                              ? "NASCONDI PIANI FUTURI"
                              : "VEDI PIANI FUTURI",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (_mostraFuturi) ...[
                      const SizedBox(height: 15),
                      ..._pianiFuturi.map(
                        (p) => _buildCardPiano(Map<String, dynamic>.from(p)),
                      ),
                    ],
                  ],

                  // --- SEZIONE STORICO ---
                  if (_pianiPassati.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(thickness: 0.5),
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _mostraPassati = !_mostraPassati),
                        icon: Icon(
                          _mostraPassati
                              ? Icons.keyboard_arrow_up
                              : Icons.history,
                          color: Colors.grey,
                          size: 20,
                        ),
                        label: Text(
                          _mostraPassati
                              ? "NASCONDI STORICO"
                              : "VEDI STORICO PIANI",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (_mostraPassati) ...[
                      const SizedBox(height: 15),
                      ..._pianiPassati.map(
                        (p) => _buildCardPiano(Map<String, dynamic>.from(p)),
                      ),
                    ],
                  ],
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildSezioneTitolo(String titolo) {
    return Text(
      titolo,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Colors.blueGrey,
        fontSize: 12,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildEmptyMsg(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        msg,
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCardPiano(Map<String, dynamic> piano) {
    String stato = piano['stato'] ?? "attivo";
    bool isPassato = stato == "passato";
    bool isFuturo = stato == "futuro";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPassato
            ? Colors.grey.shade50
            : (isFuturo ? const Color(0xFFF0F7FF) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPassato
              ? Colors.grey.shade200
              : (isFuturo
                    ? Colors.blue.shade100
                    : Colors.black.withOpacity(0.08)),
        ),
        boxShadow: (isPassato || isFuturo)
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (piano['day_of_week'] ?? "Allenamento")
                      .toString()
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: isPassato
                        ? Colors.grey
                        : (isFuturo ? Colors.blueGrey : Colors.black),
                  ),
                ),
                const SizedBox(height: 8),
                // --- NUOVA IMPOSTAZIONE RICHIESTA ---
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Inizio previsto: ${piano['dataInizioFormattata']}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Durata: ${piano['duration_weeks']} settimane",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // ------------------------------------
                if (piano['testoSettimana'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPassato
                            ? Colors.grey.shade200
                            : (isFuturo
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.blueAccent.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        piano['testoSettimana'],
                        style: TextStyle(
                          color: isPassato
                              ? Colors.grey
                              : (isFuturo ? Colors.blue : Colors.blueAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: isPassato
                ? Colors.grey.shade300
                : (isFuturo ? Colors.blue.shade300 : Colors.black),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                widget.vaiAListaEsercizi(
                  Map<String, dynamic>.from(piano),
                  widget.nomeAtleta,
                  piano['settimanaCorrente'] ?? 1,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
