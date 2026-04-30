import 'package:flutter/material.dart';
import '../services/database_service.dart';

class EserciziListaView extends StatefulWidget {
  final String planId;
  final int durataSettimane;
  final VoidCallback vaiIndietro;
  final Function(String planId, int sett) vaiAAggiungiEsercizio;
  final Function(List<dynamic> lista, int index, int sett) vaiADettaglio;
  final Function(dynamic esercizio, int sett) vaiAModifica;

  const EserciziListaView({
    super.key,
    required this.planId,
    required this.durataSettimane,
    required this.vaiIndietro,
    required this.vaiAAggiungiEsercizio,
    required this.vaiADettaglio,
    required this.vaiAModifica,
  });

  @override
  State<EserciziListaView> createState() => _EserciziListaViewState();
}

class _EserciziListaViewState extends State<EserciziListaView> {
  int _settimanaAttuale = 1;
  bool _modalitaRiordino = false;
  List<dynamic> _esercizi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _caricaEsercizi();
  }

  Future<void> _caricaEsercizi() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final dati = await DatabaseService.getEserciziPiano(
        widget.planId,
        _settimanaAttuale,
      );
      if (mounted) {
        setState(() {
          _esercizi = dati;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint("Errore caricamento esercizi: $e");
    }
  }

  void _gestisciAggiuntaEsercizio() async {
    await widget.vaiAAggiungiEsercizio(widget.planId, _settimanaAttuale);
    _caricaEsercizi();
  }

  void _gestisciModificaEsercizio(dynamic es) async {
    await widget.vaiAModifica(es, _settimanaAttuale);
    _caricaEsercizi();
  }

  void _gestisciVisualizzazioneDettaglio(int index) async {
    await widget.vaiADettaglio(_esercizi, index, _settimanaAttuale);
    _caricaEsercizi();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _esercizi.removeAt(oldIndex);
      _esercizi.insert(newIndex, item);
    });
  }

  Future<void> _salvaNuovoOrdine() async {
    setState(() => _loading = true);
    try {
      for (int i = 0; i < _esercizi.length; i++) {
        await DatabaseService.spostaEsercizio(_esercizi[i]['id'].toString(), i);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ordine salvato con successo!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Errore salvataggio ordine: $e");
    } finally {
      setState(() {
        _modalitaRiordino = false;
        _loading = false;
      });
      _caricaEsercizi();
    }
  }

  void _confermaCopiaSettimana() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Copia Settimana 1"),
        content: const Text(
          "Vuoi copiare tutti gli esercizi della Settimana 1 in tutte le altre settimane del piano? Questa operazione sovrascriverà eventuali esercizi già presenti.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(context);
              final res = await DatabaseService.copiaSettimanaUno(
                widget.planId,
                widget.durataSettimane,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['msg']),
                    backgroundColor: res['success'] ? Colors.green : Colors.red,
                  ),
                );
                if (res['success']) _caricaEsercizi();
              }
            },
            child: const Text(
              "Conferma",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confermaElimina(dynamic es) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Conferma"),
        content: Text("Vuoi eliminare ${es['exercise_name']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService.eliminaEsercizio(es['id'].toString());
              _caricaEsercizi();
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.white)),
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
                const Center(
                  child: Text(
                    "PROGRAMMAZIONE",
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SELEZIONA SETTIMANA:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.durataSettimane,
                itemBuilder: (context, i) {
                  int n = i + 1;
                  bool isActive = n == _settimanaAttuale;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _settimanaAttuale = n;
                          _modalitaRiordino = false;
                        });
                        _caricaEsercizi();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.blue
                            : Colors.grey[100],
                        foregroundColor: isActive ? Colors.white : Colors.blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("SETT $n"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _gestisciAggiuntaEsercizio,
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                "AGGIUNGI ESERCIZIO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_settimanaAttuale == 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: OutlinedButton.icon(
                        onPressed: _confermaCopiaSettimana,
                        icon: const Icon(Icons.copy_all, size: 18),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text(
                          "COPIA SETT. 1",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_modalitaRiordino) {
                          _salvaNuovoOrdine();
                        } else {
                          setState(() => _modalitaRiordino = true);
                        }
                      },
                      icon: Icon(
                        _modalitaRiordino
                            ? Icons.check_circle
                            : Icons.swap_vert,
                        size: 18,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _modalitaRiordino
                            ? Colors.green
                            : Colors.blueGrey[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      label: Text(
                        _modalitaRiordino ? "SALVA ORDINE" : "RIORDINA",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : RefreshIndicator(
                      onRefresh: _caricaEsercizi,
                      child: _esercizi.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    "Nessun esercizio per la Settimana $_settimanaAttuale",
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _modalitaRiordino
                          ? ReorderableListView.builder(
                              onReorder: _onReorder,
                              itemCount: _esercizi.length,
                              itemBuilder: (context, index) {
                                final es = _esercizi[index];
                                return _buildCardEsercizio(
                                  es,
                                  index,
                                  isReorderable: true,
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: _esercizi.length,
                              itemBuilder: (context, index) {
                                final es = _esercizi[index];
                                return _buildCardEsercizio(
                                  es,
                                  index,
                                  isReorderable: false,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardEsercizio(
    dynamic es,
    int index, {
    required bool isReorderable,
  }) {
    return Container(
      key: ValueKey(es['id']),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (isReorderable)
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Icons.drag_handle, color: Colors.blue),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
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
                            (es['exercise_name']?.toString().toUpperCase() ??
                            "ESERCIZIO"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Serie e Reps: ${es['sets_reps'] ?? 'N/D'}",
                  style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isReorderable)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  onPressed: () => _gestisciVisualizzazioneDettaglio(index),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  onPressed: () => _gestisciModificaEsercizio(es),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confermaElimina(es),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
