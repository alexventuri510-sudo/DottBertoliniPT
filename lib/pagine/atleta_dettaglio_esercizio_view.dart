import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AtletaDettaglioEsercizioView extends StatelessWidget {
  final List<dynamic> listaEsercizi;
  final int indiceAttuale;
  final VoidCallback vaiIndietro;
  final Function(int) cambiaEsercizio;

  const AtletaDettaglioEsercizioView({
    super.key,
    required this.listaEsercizi,
    required this.indiceAttuale,
    required this.vaiIndietro,
    required this.cambiaEsercizio,
  });

  // Funzione per aprire il video
  Future<void> _apriVideo(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Errore apertura video: $e');
    }
  }

  // Helper per estrarre valori in modo sicuro dalle stringhe CSV
  String _getVal(List<String> lista, int index) {
    if (index >= 0 && index < lista.length) {
      String val = lista[index].trim();
      return val.isEmpty ? "-" : val;
    }
    return "-";
  }

  @override
  Widget build(BuildContext context) {
    if (listaEsercizi.isEmpty) {
      return const Scaffold(body: Center(child: Text("Nessun dato")));
    }

    final dati = listaEsercizi[indiceAttuale];

    // Recupero dati base
    final String nome = (dati['exercise_name'] ?? "Esercizio")
        .toString()
        .toUpperCase();
    final String target = dati['sets_reps'] ?? "-";
    final String recupero = (dati['rest_seconds'] ?? "0").toString();
    final String notePt = dati['trainer_notes'] ?? "Nessuna nota inserita.";
    final String noteAtleta =
        dati['athlete_notes'] ?? "Nessuna nota registrata.";
    final String videoLink = (dati['video_link'] ?? "").toString().trim();
    final int nSerie = dati['series_count'] ?? 1;

    List<String> pesiScorsi = (dati['series_weights_scorsi']?.toString() ?? "")
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> pesiOggi = (dati['series_weights_atleta']?.toString() ?? "")
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> repsOggi = (dati['series_reps_atleta']?.toString() ?? "")
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();

    // Logica per la visibilità dei pulsanti
    bool isPrimo = indiceAttuale == 0;
    bool isUltimo = indiceAttuale == listaEsercizi.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Rimuove il back button di default
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
                // Pulsante Indietro (Stesso stile di AtletaPianiView)
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
                // Titolo centrato
                Center(
                  child: Text(
                    "ESERCIZIO ${indiceAttuale + 1} DI ${listaEsercizi.length}",
                    style: const TextStyle(
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          key: ValueKey<int>(
            indiceAttuale,
          ), // Permette l'animazione al cambio esercizio
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SCHEDA INFO ESERCIZIO ---
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
                    _buildIconInfo(
                      Icons.fitness_center,
                      "Serie e Reps: $target",
                    ),
                    const SizedBox(height: 8),
                    _buildIconInfo(
                      Icons.timer_outlined,
                      "Recupero: $recupero secondi",
                    ),
                    const Divider(height: 30),
                    const Text(
                      "NOTE DEL TRAINER:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notePt,
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
              // --- SCHEDA DATI ATLETA ---
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
                        Icon(
                          Icons.assignment_turned_in,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "DATI REGISTRATI",
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
                                "${_getVal(pesiOggi, i)} kg",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                _getVal(repsOggi, i),
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
                      "LE TUE NOTE:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      noteAtleta,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (videoLink.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _apriVideo(videoLink),
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
              // --- NAVIGAZIONE AGGIORNATA ---
              Row(
                children: [
                  // Pulsante PRECEDENTE
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

                  // Spazio aggiunto se entrambi i pulsanti sono visibili (ovvero non è il primo esercizio)
                  if (!isPrimo) const SizedBox(width: 15),

                  // Pulsante SUCCESSIVO o FINE (Torna alla lista)
                  Expanded(
                    child: isUltimo
                        ? ElevatedButton.icon(
                            onPressed: vaiIndietro,
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
