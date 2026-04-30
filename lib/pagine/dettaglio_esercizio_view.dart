import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DettaglioEsercizioView extends StatelessWidget {
  final List<dynamic> listaEsercizi;
  final int indiceAttuale;
  final VoidCallback vaiIndietro;
  final Function(int) cambiaEsercizio;

  const DettaglioEsercizioView({
    super.key,
    required this.listaEsercizi,
    required this.indiceAttuale,
    required this.vaiIndietro,
    required this.cambiaEsercizio,
  });

  // Funzione di utilità per gestire i valori nulli o vuoti delle liste CSV
  String _getVal(List<String> lista, int index) {
    if (index >= lista.length || lista[index].trim().isEmpty) return "-";
    return lista[index].trim();
  }

  Future<void> _apriVideo(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Errore apertura video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (listaEsercizi.isEmpty) {
      return const Scaffold(body: Center(child: Text("Nessun dato")));
    }

    final dati = listaEsercizi[indiceAttuale];

    // Recupero dati e parsing multi-serie
    final String nome = (dati['exercise_name'] ?? "Esercizio")
        .toString()
        .toUpperCase();
    final String target = dati['sets_reps'] ?? "-";
    final String recupero = dati['rest_seconds']?.toString() ?? "0";
    final String notePT = dati['trainer_notes'] ?? "Nessuna nota inserita.";
    final String noteAtleta =
        dati['athlete_notes'] ?? "L'atleta non ha inserito note.";
    final String linkVideo = dati['video_link'] ?? "";
    final int nSerie = dati['series_count'] ?? 1;

    final List<String> pesiAtleta = (dati['series_weights_atleta'] ?? "")
        .toString()
        .split(',');
    final List<String> repsAtleta = (dati['series_reps_atleta'] ?? "")
        .toString()
        .split(',');
    final List<String> pesiScorsi = (dati['series_weights_scorsi'] ?? "")
        .toString()
        .split(',');

    // Logica per la visibilità dei pulsanti
    bool isPrimo = indiceAttuale == 0;
    bool isUltimo = indiceAttuale == listaEsercizi.length - 1;

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
                        onPressed: vaiIndietro,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "REPORT ATLETA",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // SCHEDA 1: INFO ESERCIZIO (PT)
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
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(Icons.fitness_center, "Serie e Reps: $target"),
                  const SizedBox(height: 8),
                  _buildIconInfo(
                    Icons.timer_outlined,
                    "Recupero: $recupero secondi",
                  ),
                  const Divider(height: 30),
                  const Text(
                    "TUE NOTE:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notePT,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // SCHEDA 2: PERFORMANCE ATLETA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.insights, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "PERFORMANCE ATLETA",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _headerCell("Serie", 1),
                      _headerCell("Kg prec.", 2),
                      _headerCell("Kg oggi", 2, color: Colors.blue),
                      _headerCell("Reps", 1, color: Colors.blue),
                    ],
                  ),
                  const Divider(height: 20),
                  for (int i = 0; i < nSerie; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "${_getVal(pesiAtleta, i)} kg",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              _getVal(repsAtleta, i),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 30),
                  const Text(
                    "NOTE DELL'ATLETA:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      noteAtleta,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            if (linkVideo.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _apriVideo(linkVideo),
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text("GUARDA VIDEO TUTORIAL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            // NAVIGAZIONE AGGIORNATA
            Row(
              children: [
                // PRECEDENTE
                Expanded(
                  child: !isPrimo
                      ? ElevatedButton.icon(
                          onPressed: () => cambiaEsercizio(indiceAttuale - 1),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text("PRECEDENTE"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Modifica qui: aggiungiamo lo spazio se non siamo al primo esercizio
                // (così appare sia con "SUCCESSIVO" che con "FINE")
                if (!isPrimo) const SizedBox(width: 15),
                // SUCCESSIVO o TORNA ALLA LISTA ESERCIZI
                Expanded(
                  child: isUltimo
                      ? ElevatedButton.icon(
                          onPressed: vaiIndietro, // Torna alla lista
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text("FINE"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => cambiaEsercizio(indiceAttuale + 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _headerCell(String testo, int flex, {Color color = Colors.blueGrey}) {
    return Expanded(
      flex: flex,
      child: Text(
        testo,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
