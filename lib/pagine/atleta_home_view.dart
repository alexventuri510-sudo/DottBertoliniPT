import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AtletaHomeView extends StatefulWidget {
  final String nome;
  final String codice;
  final VoidCallback logout;
  final VoidCallback vaiAPianiPersonali;
  final VoidCallback vaiAProfilo;
  final Function(Map<String, dynamic>, String, int, String) vaiAEsercizi;

  const AtletaHomeView({
    super.key,
    required this.nome,
    required this.codice,
    required this.logout,
    required this.vaiAPianiPersonali,
    required this.vaiAProfilo,
    required this.vaiAEsercizi,
  });

  @override
  State<AtletaHomeView> createState() => _AtletaHomeViewState();
}

class _AtletaHomeViewState extends State<AtletaHomeView> {
  List<dynamic> _pianiAtleta = [];
  DateTime _dataVisualizzata = DateTime.now();
  final DateTime _oggi = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recuperoPiani();
  }

  Future<void> _recuperoPiani() async {
    try {
      final user = DatabaseService.supabase.auth.currentUser;
      if (user != null) {
        final res = await DatabaseService.getPianiAtleta(user.id);
        if (mounted) {
          setState(() {
            _pianiAtleta = res;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _vaiAProssimoAllenamento() {
    if (_pianiAtleta.isEmpty) {
      _mostraMessaggio("Nessun piano assegnato dal tuo trainer.");
      return;
    }

    DateTime oggiSenzaOra = DateTime(_oggi.year, _oggi.month, _oggi.day);
    Map<String, dynamic>? pianoTarget;
    int settimanaTarget = 1;
    String dataTargetStr = oggiSenzaOra.toIso8601String();
    Duration minDiff = const Duration(days: 9999);

    for (var p in _pianiAtleta) {
      if (p['start_date'] == null) continue;
      DateTime startDate = DateTime.parse(p['start_date']);
      int durata = p['duration_weeks'] ?? 1;

      for (int i = 0; i < durata; i++) {
        DateTime dataSettimana = startDate.add(Duration(days: i * 7));
        Duration diff = dataSettimana.difference(oggiSenzaOra);

        if (!diff.isNegative && diff < minDiff) {
          minDiff = diff;
          pianoTarget = Map<String, dynamic>.from(p);
          settimanaTarget = i + 1;
          dataTargetStr = dataSettimana.toIso8601String();
        }
      }
    }

    if (pianoTarget != null) {
      widget.vaiAEsercizi(
        pianoTarget,
        widget.nome,
        settimanaTarget,
        dataTargetStr,
      );
    } else {
      _mostraMessaggio("Nessun allenamento futuro trovato.");
    }
  }

  void _mostraMessaggio(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.black87),
    );
  }

  Future<void> _selezionaData() async {
    try {
      final DateTime? scelta = await showDatePicker(
        context: context,
        initialDate: _dataVisualizzata,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        helpText: "SELEZIONA MESE E ANNO",
        locale: const Locale('it', 'IT'),
      );
      if (scelta != null) {
        setState(() {
          _dataVisualizzata = DateTime(scelta.year, scelta.month);
        });
      }
    } catch (e) {
      final DateTime? scelta = await showDatePicker(
        context: context,
        initialDate: _dataVisualizzata,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (scelta != null) {
        setState(() => _dataVisualizzata = DateTime(scelta.year, scelta.month));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bentornato,",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.vaiAProfilo,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF1565C0),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
              onRefresh: _recuperoPiani,
              color: Colors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 35),
                    const Text(
                      "CALENDARIO ALLENAMENTI",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.blueGrey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildCalendarioCard(),
                    const SizedBox(height: 40),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalendarioCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildCalendarioContent(),
    );
  }

  Widget _buildCalendarioContent() {
    final mesiIta = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _calendarNavIcon(Icons.chevron_left, () => _cambiaMese(-1)),
            GestureDetector(
              onTap: _selezionaData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${mesiIta[_dataVisualizzata.month - 1]} ${_dataVisualizzata.year}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _calendarNavIcon(Icons.chevron_right, () => _cambiaMese(1)),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettimanaHeader(),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: 15),
        _buildGrigliaGiorni(),
      ],
    );
  }

  void _cambiaMese(int delta) {
    setState(() {
      _dataVisualizzata = DateTime(
        _dataVisualizzata.year,
        _dataVisualizzata.month + delta,
      );
    });
  }

  Widget _calendarNavIcon(IconData icon, VoidCallback action) {
    return IconButton(
      onPressed: action,
      icon: Icon(icon, color: Colors.black87),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildSettimanaHeader() {
    const giorni = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: giorni
          .map(
            (g) => Expanded(
              child: Center(
                child: Text(
                  g,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrigliaGiorni() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _dataVisualizzata.year,
      _dataVisualizzata.month,
    );
    final firstDayOfMonth = DateTime(
      _dataVisualizzata.year,
      _dataVisualizzata.month,
      1,
    );
    int firstDayOffset = firstDayOfMonth.weekday - 1;

    Map<int, Map<String, dynamic>> allenamentiDelMese = {};
    for (var p in _pianiAtleta) {
      if (p['start_date'] == null) continue;
      DateTime start = DateTime.parse(p['start_date']);
      for (int i = 0; i < (p['duration_weeks'] ?? 1); i++) {
        DateTime d = start.add(Duration(days: i * 7));
        if (d.month == _dataVisualizzata.month &&
            d.year == _dataVisualizzata.year) {
          allenamentiDelMese[d.day] = {
            "piano": Map<String, dynamic>.from(p),
            "settimana": i + 1,
            "dataISO": d.toIso8601String(),
          };
        }
      }
    }

    int totaleCelle = firstDayOffset + daysInMonth;
    int righeNecessarie = (totaleCelle / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: righeNecessarie * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        int giorno = index - firstDayOffset + 1;
        if (index < firstDayOffset || giorno > daysInMonth) {
          return const SizedBox.shrink();
        }

        DateTime dataCella = DateTime(
          _dataVisualizzata.year,
          _dataVisualizzata.month,
          giorno,
        );
        bool isToday = DateUtils.isSameDay(dataCella, _oggi);
        bool hasWorkout = allenamentiDelMese.containsKey(giorno);

        return GestureDetector(
          onTap: hasWorkout
              ? () => widget.vaiAEsercizi(
                  allenamentiDelMese[giorno]!['piano'],
                  widget.nome,
                  allenamentiDelMese[giorno]!['settimana'],
                  allenamentiDelMese[giorno]!['dataISO'],
                )
              : null,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasWorkout
                  ? Colors.green.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday
                  ? Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$giorno",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday
                        ? FontWeight.w900
                        : (hasWorkout ? FontWeight.w800 : FontWeight.w500),
                    color: isToday
                        ? Colors.blueAccent
                        : (hasWorkout ? Colors.green.shade700 : Colors.black87),
                  ),
                ),
                if (hasWorkout)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _btn(
          "INIZIA ALLENAMENTO",
          Icons.play_arrow_rounded,
          _vaiAProssimoAllenamento,
          Colors.green, // Sfondo Verde come richiesto
        ),
        const SizedBox(height: 16),
        _btn(
          "VISUALIZZA PIANI ALLENAMENTO",
          Icons.fitness_center_rounded,
          widget.vaiAPianiPersonali,
          Colors.blue.shade700, // Sfondo Blu come richiesto
          textCol: Colors.white, // Testo bianco per leggibilità
        ),
      ],
    );
  }

  Widget _btn(
    String label,
    IconData icon,
    VoidCallback tap,
    Color bg, {
    Color textCol = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: tap,
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textCol,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
