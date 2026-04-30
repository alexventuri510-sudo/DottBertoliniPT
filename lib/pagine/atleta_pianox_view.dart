import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Necessario per l'italiano
import '../services/database_service.dart';

class AtletaPianoXView extends StatefulWidget {
  final String planId;
  final int settimana;
  final String nomeAtleta;
  final VoidCallback vaiIndietro;
  final Future<bool> Function(List<dynamic>, int, int) vaiADettaglioEsercizio;
  final String? dataPianoStr;

  const AtletaPianoXView({
    super.key,
    required this.planId,
    required this.settimana,
    required this.nomeAtleta,
    required this.vaiIndietro,
    required this.vaiADettaglioEsercizio,
    this.dataPianoStr,
  });

  @override
  State<AtletaPianoXView> createState() => _AtletaPianoXViewState();
}

class _AtletaPianoXViewState extends State<AtletaPianoXView> {
  List<dynamic> _esercizi = [];
  bool _isLoading = true;
  String _titoloGiorno = "SESSIONE DI ALLENAMENTO";
  String _dataInizioSottotitolo = "";

  @override
  void initState() {
    super.initState();
    _inizializzaDati();
  }

  void _inizializzaDati() async {
    await initializeDateFormatting('it_IT', null);
    _preparaDate();
    _caricaEsercizi();
  }

  void _preparaDate() {
    if (widget.dataPianoStr != null && widget.dataPianoStr!.isNotEmpty) {
      try {
        DateTime dataPiano;
        String cleanDate = widget.dataPianoStr!.trim();

        if (cleanDate.contains("T")) {
          dataPiano = DateTime.parse(cleanDate).toLocal();
        } else {
          dataPiano = DateFormat("yyyy-MM-dd").parse(cleanDate);
        }

        String giornoSettimana = DateFormat(
          'EEEE',
          'it_IT',
        ).format(dataPiano).toUpperCase();

        String dataFormattata = DateFormat('dd/MM/yyyy').format(dataPiano);

        setState(() {
          _titoloGiorno = "ALLENAMENTO DI $giornoSettimana";
          _dataInizioSottotitolo = "Sessione del $dataFormattata";
        });
      } catch (e) {
        debugPrint(
          "DEBUG: Errore parsing data in PianoX: $e - Stringa ricevuta: ${widget.dataPianoStr}",
        );
        setState(() {
          _titoloGiorno = "SESSIONE DI ALLENAMENTO";
          _dataInizioSottotitolo = "Data non disponibile";
        });
      }
    }
  }

  Future<void> _caricaEsercizi() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final dati = await DatabaseService.getEserciziPiano(
        widget.planId,
        widget.settimana,
      );

      if (mounted) {
        setState(() {
          _esercizi = dati;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("DEBUG: Errore caricamento esercizi PianoX: $e");
      if (mounted) setState(() => _isLoading = false);
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
                    "DETTAGLIO SESSIONE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Text(
                  _titoloGiorno,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "SETTIMANA ${widget.settimana}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_dataInizioSottotitolo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _dataInizioSottotitolo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _esercizi.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    itemCount: _esercizi.length,
                    itemBuilder: (context, index) {
                      final es = Map<String, dynamic>.from(_esercizi[index]);
                      return _buildEsercizioCard(es, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsercizioCard(Map<String, dynamic> es, int index) {
    final String pesiSalvati = (es['series_weights_atleta']?.toString() ?? "")
        .trim();
    final String noteAtleta = (es['athlete_notes']?.toString() ?? "").trim();

    final bool isCompletato =
        (pesiSalvati.isNotEmpty &&
            pesiSalvati.split(',').any((v) {
              final cleanV = v.trim();
              return cleanV.isNotEmpty && cleanV != "-" && cleanV != "0";
            })) ||
        noteAtleta.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompletato ? Colors.green.shade400 : Colors.grey.shade200,
          width: isCompletato ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          "${index + 1}) ${es['exercise_name']?.toString().toUpperCase() ?? 'ESERCIZIO'}",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            "Serie e Reps: ${es['sets_reps'] ?? '-'}",
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final result = await widget.vaiADettaglioEsercizio(
              _esercizi,
              index,
              widget.settimana,
            );

            if (result == true) {
              _caricaEsercizi();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompletato ? Colors.green : Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isCompletato ? "MODIFICA" : "INIZIA",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 60,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          const Text(
            "Nessun esercizio in questa sessione.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
