import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class PianiAllenamentoView extends StatefulWidget {
  final String atletaId;
  final String nomeAtleta;
  final VoidCallback vaiIndietro;
  final Function(String id, String nome) vaiACreaPiano;
  final Function(dynamic piano) vaiAListaEsercizi;

  const PianiAllenamentoView({
    super.key,
    required this.atletaId,
    required this.nomeAtleta,
    required this.vaiIndietro,
    required this.vaiACreaPiano,
    required this.vaiAListaEsercizi,
  });

  @override
  State<PianiAllenamentoView> createState() => _PianiAllenamentoViewState();
}

class _PianiAllenamentoViewState extends State<PianiAllenamentoView> {
  bool _mostraPassati = false;
  bool _mostraFuturi = false;
  late Future<List<dynamic>> _futurePiani;

  final Map<String, int> _ordineGiorni = {
    "Lunedì": 1,
    "Martedì": 2,
    "Mercoledì": 3,
    "Giovedì": 4,
    "Venerdì": 5,
    "Sabato": 6,
    "Domenica": 7,
  };

  @override
  void initState() {
    super.initState();
    _caricaPiani();
  }

  void _caricaPiani() {
    setState(() {
      _futurePiani = DatabaseService.getPianiAtleta(widget.atletaId);
    });
  }

  Future<void> _gestisciNuovoPiano() async {
    await widget.vaiACreaPiano(widget.atletaId, widget.nomeAtleta);
    _caricaPiani();
  }

  void _confermaEliminazione(String pid, String giorno) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Conferma eliminazione"),
        content: Text("Sei sicuro di voler eliminare il piano di $giorno?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await DatabaseService.eliminaPianoAllenamento(
                pid,
              );
              if (success) {
                _caricaPiani();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Piano di $giorno eliminato")),
                  );
                }
              }
            },
            child: const Text(
              "Sì, elimina",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
                Center(
                  child: Text(
                    "PIANI DI ${widget.nomeAtleta.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: ElevatedButton(
              onPressed: _gestisciNuovoPiano,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "CREA NUOVO PIANO",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _caricaPiani(),
              color: Colors.black,
              child: FutureBuilder<List<dynamic>>(
                future: _futurePiani,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  final piani = snapshot.data ?? [];

                  if (piani.isEmpty) {
                    return _buildEmptyMsg(
                      "Nessun allenamento programmato per questo atleta.",
                    );
                  }

                  List<dynamic> attivi = [];
                  List<dynamic> passati = [];
                  List<dynamic> futuri = [];

                  DateTime oggi = DateTime.now();
                  DateTime oggiSoloData = DateTime(
                    oggi.year,
                    oggi.month,
                    oggi.day,
                  );

                  for (var p in piani) {
                    DateTime startDate = DateTime.parse(p['start_date']);
                    int durationWeeks = p['duration_weeks'] ?? 0;
                    DateTime scadenza = startDate.add(
                      Duration(days: (durationWeeks * 7) - 1),
                    );

                    if (oggiSoloData.isBefore(startDate)) {
                      futuri.add(p);
                    } else if (oggiSoloData.isAfter(scadenza)) {
                      passati.add(p);
                    } else {
                      attivi.add(p);
                    }
                  }

                  attivi.sort(
                    (a, b) => (_ordineGiorni[a['day_of_week']] ?? 99).compareTo(
                      _ordineGiorni[b['day_of_week']] ?? 99,
                    ),
                  );

                  futuri.sort(
                    (a, b) => DateTime.parse(
                      a['start_date'],
                    ).compareTo(DateTime.parse(b['start_date'])),
                  );

                  return ListView(
                    padding: const EdgeInsets.all(25),
                    children: [
                      _buildSezioneTitolo("PIANI IN CORSO"),
                      const SizedBox(height: 15),
                      if (attivi.isEmpty)
                        _buildEmptyMsg("Nessun piano attivo al momento.")
                      else
                        ...attivi.map(
                          (p) => _buildCardPiano(p, "attivo", oggiSoloData),
                        ),
                      if (futuri.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(thickness: 0.5),
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _mostraFuturi = !_mostraFuturi),
                            icon: Icon(
                              _mostraFuturi
                                  ? Icons.keyboard_arrow_up
                                  : Icons.event,
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
                          ...futuri.map(
                            (p) => _buildCardPiano(p, "futuro", oggiSoloData),
                          ),
                        ],
                      ],
                      if (passati.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(thickness: 0.5),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(
                              () => _mostraPassati = !_mostraPassati,
                            ),
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
                          ...passati.map(
                            (p) => _buildCardPiano(p, "passato", oggiSoloData),
                          ),
                        ],
                      ],
                      const SizedBox(height: 50),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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

  Widget _buildCardPiano(dynamic p, String stato, DateTime oggi) {
    DateTime startDate = DateTime.parse(p['start_date']);
    String dataFormattata = DateFormat('dd/MM/yyyy').format(startDate);
    int settimaneTotali = p['duration_weeks'] ?? 0;
    bool isPassato = stato == "passato";
    bool isFuturo = stato == "futuro";
    String badgeTesto = "";

    if (stato == "attivo") {
      int giorniPassati = oggi.difference(startDate).inDays;
      int settCalc = (giorniPassati ~/ 7) + 1;
      badgeTesto =
          "Settimana attuale: ${settCalc > settimaneTotali ? settimaneTotali : settCalc}";
    } else if (isFuturo) {
      badgeTesto = "Inizio programmato";
    } else {
      badgeTesto = "Completato";
    }

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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['day_of_week'].toString().toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: isPassato
                            ? Colors.grey
                            : (isFuturo ? Colors.blueGrey : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Inizio previsto: $dataFormattata",
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
                          "Durata: $settimaneTotali settimane",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
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
                        badgeTesto,
                        style: TextStyle(
                          color: isPassato
                              ? Colors.grey
                              : (isFuturo ? Colors.blue : Colors.blueAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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
                  onTap: () async {
                    await widget.vaiAListaEsercizi(p);
                    _caricaPiani();
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
          const SizedBox(height: 10),
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  _confermaEliminazione(p['id'].toString(), p['day_of_week']),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text(
                "ELIMINA PIANO",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
