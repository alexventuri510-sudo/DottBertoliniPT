import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Aggiunto per la formattazione della data
import '../services/database_service.dart';

class PtPianiInScadenzaView extends StatefulWidget {
  const PtPianiInScadenzaView({super.key});

  @override
  State<PtPianiInScadenzaView> createState() => _PtPianiInScadenzaViewState();
}

class _PtPianiInScadenzaViewState extends State<PtPianiInScadenzaView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _piani = [];

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    setState(() => _isLoading = true);
    final dati = await DatabaseService.getPianiInScadenza();

    // Ordinamento alfabetico crescente per nome atleta
    dati.sort((a, b) {
      String nomeA = (a['nome_atleta'] ?? "").toString().toLowerCase();
      String nomeB = (b['nome_atleta'] ?? "").toString().toLowerCase();
      return nomeA.compareTo(nomeB);
    });

    setState(() {
      _piani = dati;
      _isLoading = false;
    });
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "Piani in Scadenza",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _piani.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _caricaDati,
              color: Colors.black,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: _piani.length,
                itemBuilder: (context, index) {
                  final piano = _piani[index];
                  return _buildPianoCard(piano);
                },
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
            Icons.check_circle_outline_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          Text(
            "Ottimo lavoro, Coach!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            "Nessun piano in scadenza questa settimana.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPianoCard(Map<String, dynamic> piano) {
    // Formattazione della data in gg/mm/aaaa
    String dataFormattata = "";
    try {
      if (piano['start_date'] != null) {
        DateTime dt = DateTime.parse(piano['start_date'].toString());
        dataFormattata = DateFormat('dd/MM/yyyy').format(dt);
      }
    } catch (e) {
      dataFormattata = piano['start_date'].toString().split(' ')[0];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50, // Cambiato in Blu
                  child: Text(
                    piano['nome_atleta']?[0] ?? "A",
                    style: TextStyle(
                      color: Colors.blue.shade800, // Cambiato in Blu
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        piano['nome_atleta'] ?? "Atleta",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Piano: ${piano['day_of_week']}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700, // Cambiato in Rosso
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "ULTIMA SETT.",
                    style: TextStyle(
                      color: Colors.white, // Scritta Bianca
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  "Inizio",
                  dataFormattata, // Usata la data formattata gg/mm/aaaa
                ),
                _buildInfoColumn("Durata", "${piano['duration_weeks']} sett."),
                _buildInfoColumn(
                  "Settimana",
                  "${piano['settimana_attuale']}/${piano['duration_weeks']}",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
