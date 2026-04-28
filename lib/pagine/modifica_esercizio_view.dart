import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModificaEsercizioView extends StatefulWidget {
  final Map<String, dynamic> datiEsercizio;
  final VoidCallback vaiIndietro;

  const ModificaEsercizioView({
    super.key,
    required this.datiEsercizio,
    required this.vaiIndietro,
  });

  @override
  State<ModificaEsercizioView> createState() => _ModificaEsercizioViewState();
}

class _ModificaEsercizioViewState extends State<ModificaEsercizioView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _setsRepsController;
  late TextEditingController _seriesCountController;
  late TextEditingController _restSecondsController;
  late TextEditingController _linkController;
  late TextEditingController _trainerNotesController;

  bool _caricamento = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.datiEsercizio['exercise_name']?.toString() ?? "",
    );
    _setsRepsController = TextEditingController(
      text: widget.datiEsercizio['sets_reps']?.toString() ?? "",
    );
    _seriesCountController = TextEditingController(
      text: widget.datiEsercizio['series_count']?.toString() ?? "1",
    );
    _restSecondsController = TextEditingController(
      text: widget.datiEsercizio['rest_seconds']?.toString() ?? "0",
    );
    _linkController = TextEditingController(
      text: widget.datiEsercizio['video_link']?.toString() ?? "",
    );
    _trainerNotesController = TextEditingController(
      text: widget.datiEsercizio['trainer_notes']?.toString() ?? "",
    );
  }

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

  Future<void> _salvaModifiche() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _caricamento = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('exercises')
          .update({
            'exercise_name': _nomeController.text.trim(),
            'sets_reps': _setsRepsController.text.trim(),
            'series_count': int.tryParse(_seriesCountController.text) ?? 1,
            'rest_seconds': int.tryParse(_restSecondsController.text) ?? 0,
            'video_link': _linkController.text.trim(),
            'trainer_notes': _trainerNotesController.text.trim(),
          })
          .eq('id', widget.datiEsercizio['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Esercizio aggiornato con successo!"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore: $e"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Grigio chiarissimo di sfondo
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.blue,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "MODIFICA ESERCIZIO",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildSectionTitle("PARAMETRI ALLENAMENTO"),
              _buildCard([
                _inputField(
                  _nomeController,
                  "Nome Esercizio",
                  icon: Icons.fitness_center,
                ),
                _inputField(
                  _setsRepsController,
                  "Serie e Ripetizioni (es: 4 x 10)",
                  icon: Icons.repeat,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _inputField(
                        _seriesCountController,
                        "Serie (N°)",
                        isNumber: true,
                        icon: Icons.format_list_numbered,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _inputField(
                        _restSecondsController,
                        "Recupero (sec)",
                        isNumber: true,
                        icon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 25),
              _buildSectionTitle("CONTENUTI E NOTE"),
              _buildCard([
                _inputField(
                  _linkController,
                  "Link Video Tutorial (URL)",
                  icon: Icons.play_circle_outline,
                ),
                _inputField(
                  _trainerNotesController,
                  "Note Tecniche per l'Atleta",
                  icon: Icons.edit_note,
                  maxLines: 4,
                ),
              ]),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _caricamento ? null : _salvaModifiche,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _caricamento
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "SALVA MODIFICHE",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(children: children),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: Colors.blue.shade400)
              : null,
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blueGrey.shade400,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFFFBFDFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade200),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
        ),
        validator: (v) {
          if ((v == null || v.isEmpty) && label.contains("Nome")) {
            return "Campo obbligatorio";
          }
          return null;
        },
      ),
    );
  }
}
