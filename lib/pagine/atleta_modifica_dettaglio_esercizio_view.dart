import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class AtletaModificaDettaglioEsercizioView extends StatefulWidget {
  final List<dynamic> listaEsercizi;
  final int indiceAttuale;
  final VoidCallback vaiIndietro;
  final Function(String id, List<String> pesi, List<String> reps, String note)
  salvaDati;
  final Function(int) cambiaEsercizio;

  const AtletaModificaDettaglioEsercizioView({
    super.key,
    required this.listaEsercizi,
    required this.indiceAttuale,
    required this.vaiIndietro,
    required this.salvaDati,
    required this.cambiaEsercizio,
  });

  @override
  State<AtletaModificaDettaglioEsercizioView> createState() =>
      _AtletaModificaDettaglioEsercizioViewState();
}

class _AtletaModificaDettaglioEsercizioViewState
    extends State<AtletaModificaDettaglioEsercizioView> {
  final List<TextEditingController> _controllersKg = [];
  final List<TextEditingController> _controllersReps = [];
  final TextEditingController _controllerNote = TextEditingController();

  // --- LOGICA CRONOMETRO PROFESSIONALE ---
  bool _timerEspanso = false;
  Timer? _timer;
  final ValueNotifier<int> _millisecondiTrascorsi = ValueNotifier<int>(0);
  bool _isTimerRunning = false;

  // Variabili per il calcolo del tempo reale
  DateTime? _startTime;
  int _precedentiMillisecondi = 0;

  void _toggleTimer() {
    setState(() {
      _timerEspanso = !_timerEspanso;
    });
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    _isTimerRunning = true;

    // Memorizzo l'istante esatto di inizio
    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      // Calcolo la differenza reale tra ora e quando ho premuto play
      final now = DateTime.now();
      final differenza = now.difference(_startTime!).inMilliseconds;

      // Aggiorno il contatore sommano il tempo della sessione attuale a quelle precedenti
      _millisecondiTrascorsi.value = _precedentiMillisecondi + differenza;
    });
    setState(() {});
  }

  void _stopTimer() {
    if (!_isTimerRunning) return;
    _timer?.cancel();
    _isTimerRunning = false;
    // Salvo il tempo accumulato per poter riprendere correttamente
    _precedentiMillisecondi = _millisecondiTrascorsi.value;
    setState(() {});
  }

  void _resetTimer() {
    _stopTimer();
    _precedentiMillisecondi = 0;
    _millisecondiTrascorsi.value = 0;
  }

  String _formatTime(int milliseconds) {
    int minutes = (milliseconds ~/ 60000);
    int seconds = (milliseconds ~/ 1000) % 60;
    int hundreds = (milliseconds % 1000) ~/ 10;

    String m = minutes.toString().padLeft(2, '0');
    String s = seconds.toString().padLeft(2, '0');
    String h = hundreds.toString().padLeft(2, '0');

    return "$m:$s,$h";
  }
  // -------------------------

  @override
  void initState() {
    super.initState();
    _inizializzaCampi();
  }

  void _inizializzaCampi() {
    final dati = widget.listaEsercizi[widget.indiceAttuale];
    final int nSerie = dati['series_count'] ?? 1;

    for (var c in _controllersKg) {
      c.dispose();
    }
    for (var c in _controllersReps) {
      c.dispose();
    }
    _controllersKg.clear();
    _controllersReps.clear();

    List<String> pesiOggi = (dati['series_weights_atleta']?.toString() ?? "")
        .split(',');
    List<String> repsOggi = (dati['series_reps_atleta']?.toString() ?? "")
        .split(',');

    for (int i = 0; i < nSerie; i++) {
      _controllersKg.add(TextEditingController(text: _getVal(pesiOggi, i)));
      _controllersReps.add(TextEditingController(text: _getVal(repsOggi, i)));
    }
    _controllerNote.text = dati['athlete_notes'] ?? "";
  }

  String _getVal(List<String> lista, int index) {
    if (index >= 0 && index < lista.length) {
      return lista[index].trim();
    }
    return "";
  }

  void _eseguiSalvataggio() {
    final dati = widget.listaEsercizi[widget.indiceAttuale];
    final String idEs = dati['id'].toString();

    List<String> nuoviPesi = _controllersKg.map((c) => c.text).toList();
    List<String> nuoveReps = _controllersReps.map((c) => c.text).toList();
    String nuoveNote = _controllerNote.text;

    widget.listaEsercizi[widget.indiceAttuale]['series_weights_atleta'] =
        nuoviPesi.join(',');
    widget.listaEsercizi[widget.indiceAttuale]['series_reps_atleta'] = nuoveReps
        .join(',');
    widget.listaEsercizi[widget.indiceAttuale]['athlete_notes'] = nuoveNote;

    widget.salvaDati(idEs, nuoviPesi, nuoveReps, nuoveNote);
  }

  Future<void> _apriVideo(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _millisecondiTrascorsi.dispose();
    for (var c in _controllersKg) {
      c.dispose();
    }
    for (var c in _controllersReps) {
      c.dispose();
    }
    _controllerNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dati = widget.listaEsercizi[widget.indiceAttuale];
    final String nome = (dati['exercise_name'] ?? "Esercizio")
        .toString()
        .toUpperCase();
    final String target = dati['sets_reps'] ?? "-";
    final String recupero = (dati['rest_seconds'] ?? "0").toString();
    final String notePt = dati['trainer_notes'] ?? "Nessuna nota.";
    final String videoLink = (dati['video_link'] ?? "").toString().trim();
    List<String> pesiScorsi = (dati['series_weights_scorsi']?.toString() ?? "")
        .split(',');

    bool isPrimo = widget.indiceAttuale == 0;
    bool isUltimo = widget.indiceAttuale == widget.listaEsercizi.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _resetTimer();
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.blue,
              size: 28,
            ),
            onPressed: () {
              _resetTimer();
              Navigator.of(context).pop(true);
            },
          ),
          title: const Text(
            "LOG SESSIONE",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow(Icons.fitness_center, "Serie e Reps: $target"),
                      _infoRow(
                        Icons.timer_outlined,
                        "Recupero: $recupero secondi",
                      ),
                      const Divider(height: 25),
                      const Text(
                        "NOTE DEL TRAINER:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        notePt,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            "INSERISCI DATI",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _headerCol("Serie", 1),
                          _headerCol("Kg prec.", 2),
                          _headerCol("Kg oggi", 2, color: Colors.blue),
                          _headerCol("Reps", 2, color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (int i = 0; i < _controllersKg.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "${i + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${_getVal(pesiScorsi, i)} kg",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: TextField(
                                    controller: _controllersKg[i],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _inputStyle(hint: "0"),
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => _eseguiSalvataggio(),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _controllersReps[i],
                                  keyboardType: TextInputType.number,
                                  decoration: _inputStyle(hint: "0"),
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => _eseguiSalvataggio(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 30),
                      const Text(
                        "NOTE PERSONALI:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controllerNote,
                        maxLines: 2,
                        decoration: _inputStyle(hint: "Com'è andata?"),
                        onChanged: (_) => _eseguiSalvataggio(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (videoLink.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _apriVideo(videoLink),
                      icon: const Icon(Icons.play_circle_fill),
                      label: const Text("VIDEO TUTORIAL"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey[800],
                        side: BorderSide(color: Colors.blueGrey.shade800),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                // --- SEZIONE CRONOMETRO AGGIORNATA ---
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: _toggleTimer,
                        leading: const Icon(
                          Icons.timer,
                          color: Colors.blueGrey,
                        ),
                        title: const Text(
                          "CRONOMETRO RECUPERO",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        trailing: Icon(
                          _timerEspanso
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.blueGrey,
                        ),
                      ),
                      if (_timerEspanso)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 25,
                            left: 20,
                            right: 20,
                          ),
                          child: Column(
                            children: [
                              ValueListenableBuilder<int>(
                                valueListenable: _millisecondiTrascorsi,
                                builder: (context, value, child) {
                                  return Text(
                                    _formatTime(value),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_isTimerRunning)
                                    _timerActionButton(
                                      icon: Icons.play_arrow,
                                      color: Colors.green,
                                      onPressed: _startTimer,
                                      size: 35,
                                    )
                                  else
                                    _timerActionButton(
                                      icon: Icons.pause,
                                      color: Colors.blue,
                                      onPressed: _stopTimer,
                                      size: 35,
                                    ),
                                  const SizedBox(width: 40),
                                  _timerActionButton(
                                    icon: Icons.refresh,
                                    color: Colors.red,
                                    onPressed: _resetTimer,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: !isPrimo
                          ? ElevatedButton.icon(
                              onPressed: () {
                                _eseguiSalvataggio();
                                _resetTimer();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AtletaModificaDettaglioEsercizioView(
                                          listaEsercizi: widget.listaEsercizi,
                                          indiceAttuale:
                                              widget.indiceAttuale - 1,
                                          vaiIndietro: widget.vaiIndietro,
                                          salvaDati: widget.salvaDati,
                                          cambiaEsercizio:
                                              widget.cambiaEsercizio,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chevron_left),
                              label: const Text("PRECEDENTE"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (!isPrimo && !isUltimo) const SizedBox(width: 15),
                    Expanded(
                      child: isUltimo
                          ? ElevatedButton.icon(
                              onPressed: () {
                                _eseguiSalvataggio();
                                _resetTimer();
                                Navigator.of(context).pop(true);
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("TERMINA ALLENAMENTO"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                _eseguiSalvataggio();
                                _resetTimer();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AtletaModificaDettaglioEsercizioView(
                                          listaEsercizi: widget.listaEsercizi,
                                          indiceAttuale:
                                              widget.indiceAttuale + 1,
                                          vaiIndietro: widget.vaiIndietro,
                                          salvaDati: widget.salvaDati,
                                          cambiaEsercizio:
                                              widget.cambiaEsercizio,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("SUCCESSIVO"),
                                  SizedBox(width: 5),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timerActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 28,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size),
        color: Colors.white,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _headerCol(String label, int flex, {Color color = Colors.blueGrey}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputStyle({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      fillColor: const Color(0xFFF8F9FA),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }
}
