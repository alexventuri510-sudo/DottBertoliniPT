import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AggiungiEsercizioView extends StatefulWidget {
  final String planId;
  final int weekNumber;
  final VoidCallback vaiIndietro;

  const AggiungiEsercizioView({
    super.key,
    required this.planId,
    required this.weekNumber,
    required this.vaiIndietro,
  });

  @override
  State<AggiungiEsercizioView> createState() => _AggiungiEsercizioViewState();
}

class _AggiungiEsercizioViewState extends State<AggiungiEsercizioView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _setsRepsController = TextEditingController();
  final _seriesCountController = TextEditingController();
  final _restSecondsController = TextEditingController();
  final _linkController = TextEditingController();
  final _trainerNotesController = TextEditingController();

  bool _caricamento = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _setsRepsController.dispose();
    _seriesCountController.dispose();
    _restSecondsController.dispose();
    _linkController.dispose();
    _trainerNotesController.dispose();
    super.dispose();
  }

  Future<void> _salvaEsercizio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _caricamento = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Recupero l'ultimo ordine per posizionare l'esercizio in coda
      final ultimoEs = await supabase
          .from('exercises')
          .select('exercise_order')
          .eq('plan_id', widget.planId)
          .eq('week_number', widget.weekNumber)
          .order('exercise_order', ascending: false)
          .limit(1)
          .maybeSingle();

      int nuovoOrdine = (ultimoEs != null)
          ? (ultimoEs['exercise_order'] as int) + 1
          : 0;

      // 2. Inserimento nel database
      await supabase.from('exercises').insert({
        'plan_id': widget.planId,
        'week_number': widget.weekNumber,
        'exercise_name': _nomeController.text.trim(),
        'sets_reps': _setsRepsController.text.trim(),
        'series_count': int.tryParse(_seriesCountController.text) ?? 1,
        'rest_seconds': int.tryParse(_restSecondsController.text) ?? 0,
        'video_link': _linkController.text.trim(),
        'trainer_notes': _trainerNotesController.text.trim(),
        'exercise_order': nuovoOrdine,
        'series_weights_atleta': '',
        'series_reps_atleta': '',
        'series_weights_scorsi': '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Esercizio aggiunto alla Settimana ${widget.weekNumber}!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore DB: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "NUOVO ESERCIZIO",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Settimana ${widget.weekNumber}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "DETTAGLI TECNICI",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 15),
                _inputField(
                  _nomeController,
                  "Nome Esercizio (es: Panca Piana)",
                  obbligatorio: true,
                ),
                _inputField(
                  _setsRepsController,
                  "Descrizione Serie/Reps (es: 4x10)",
                ),
                Row(
                  children: [
                    Expanded(
                      child: _inputField(
                        _seriesCountController,
                        "Num. Serie",
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _inputField(
                        _restSecondsController,
                        "Recupero (sec)",
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                const Text(
                  "NOTE E VIDEO",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 15),
                _inputField(
                  _linkController,
                  "Link Video Tutorial (YouTube/Drive)",
                ),
                _inputField(
                  _trainerNotesController,
                  "Note per l'atleta (esecuzione, varianti...)",
                  maxLines: 3,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _caricamento ? null : _salvaEsercizio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _caricamento
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "SALVA ESERCIZIO",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
    bool obbligatorio = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 1),
          ),
        ),
        validator: (v) {
          if (obbligatorio && (v == null || v.isEmpty)) {
            return "Campo obbligatorio";
          }
          return null;
        },
      ),
    );
  }
}
