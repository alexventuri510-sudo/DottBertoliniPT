import 'package:flutter/material.dart';

import '../services/database_service.dart';

class AtletaListaEserciziView extends StatefulWidget {
  final String planId;

  final String nomeAtleta;

  final String giornoSettimana; // Aggiunto per il titolo dinamico

  final int durataSettimane;

  final int settimanaIniziale;

  final VoidCallback vaiIndietro;

  final Function(List<dynamic>, int, int) vaiADettaglioEsercizio;

  const AtletaListaEserciziView({
    super.key,

    required this.planId,

    required this.nomeAtleta,

    required this.giornoSettimana, // Richiesto nel costruttore

    required this.durataSettimane,

    this.settimanaIniziale = 1,

    required this.vaiIndietro,

    required this.vaiADettaglioEsercizio,
  });

  @override
  State<AtletaListaEserciziView> createState() =>
      _AtletaListaEserciziViewState();
}

class _AtletaListaEserciziViewState extends State<AtletaListaEserciziView> {
  late int _settimanaSelezionata;

  List<dynamic> _esercizi = [];

  bool _isLoading = true;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _settimanaSelezionata = widget.settimanaIniziale;

    double initialOffset = 0;

    if (widget.settimanaIniziale > 1) {
      initialOffset = (widget.settimanaIniziale - 1) * 82.0;
    }

    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _caricaEsercizi();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _caricaEsercizi() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final dati = await DatabaseService.getEserciziPiano(
        widget.planId,

        _settimanaSelezionata,
      );

      if (mounted) {
        setState(() {
          _esercizi = dati;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento esercizi: $e");

      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cambiaSettimana(int n) {
    if (_settimanaSelezionata == n) return;

    setState(() {
      _settimanaSelezionata = n;
    });

    _caricaEsercizi();
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

        title: Text(
          "ALLENAMENTO DI ${widget.giornoSettimana.toUpperCase()}",

          style: const TextStyle(
            color: Colors.black,

            fontSize: 16,

            fontWeight: FontWeight.w900,

            letterSpacing: -0.5,
          ),
        ),

        centerTitle: true,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 10, 20, 5),

            child: Text(
              "SETTIMANA DI RIFERIMENTO:",

              style: TextStyle(
                fontSize: 10,

                fontWeight: FontWeight.w800,

                color: Colors.blueGrey,

                letterSpacing: 0.5,
              ),
            ),
          ),

          SizedBox(
            height: 60,

            child: ListView.builder(
              controller: _scrollController,

              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 15),

              itemCount: widget.durataSettimane,

              itemBuilder: (context, index) {
                int sett = index + 1;

                bool isActive = sett == _settimanaSelezionata;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,

                    vertical: 8,
                  ),

                  child: ElevatedButton(
                    onPressed: () => _cambiaSettimana(sett),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? Colors.black
                          : Colors.grey.shade100,

                      foregroundColor: isActive ? Colors.white : Colors.black,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),

                        side: BorderSide(
                          color: isActive ? Colors.black : Colors.grey.shade300,
                        ),
                      ),
                    ),

                    child: Text(
                      "SETT $sett",

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,

                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 30, thickness: 0.5),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _esercizi.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    itemCount: _esercizi.length,

                    itemBuilder: (context, index) {
                      final Map<String, dynamic> es = Map<String, dynamic>.from(
                        _esercizi[index],
                      );

                      return _buildEsercizioCard(es, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsercizioCard(Map<String, dynamic> es, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,

              fontSize: 14,

              fontFamily: 'Roboto',
            ),

            children: [
              TextSpan(
                text: "${index + 1}) ",

                style: const TextStyle(
                  fontWeight: FontWeight.w900,

                  color: Colors.black,
                ),
              ),

              TextSpan(
                text:
                    es['exercise_name']?.toString().toUpperCase() ??
                    'ESERCIZIO',

                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Text(
            "Target: ${es['sets_reps'] ?? '-'}",

            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,

          size: 14,

          color: Colors.black26,
        ),

        onTap: () async {
          await widget.vaiADettaglioEsercizio(
            _esercizi,

            index,

            _settimanaSelezionata,
          );

          _caricaEsercizi();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            Icons.fitness_center_outlined,

            size: 40,

            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 10),

          Text(
            "Nessun esercizio presente",

            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
