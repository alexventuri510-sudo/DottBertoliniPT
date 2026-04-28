import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PtProfiloView extends StatefulWidget {
  final String userId;
  final VoidCallback tornaHome;
  final VoidCallback logout;

  const PtProfiloView({
    super.key,
    required this.userId,
    required this.tornaHome,
    required this.logout,
  });

  @override
  State<PtProfiloView> createState() => _PtProfiloViewState();
}

class _PtProfiloViewState extends State<PtProfiloView> {
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  String _codiceTrainer = "Caricamento...";
  bool _caricamento = true;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    try {
      final profilo = await DatabaseService.getProfiloCompleto(widget.userId);
      if (profilo != null) {
        setState(() {
          _nomeController.text = profilo['first_name'] ?? "";
          _cognomeController.text = profilo['last_name'] ?? "";
          _codiceTrainer = profilo['unique_code'] ?? "N/D";
          _caricamento = false;
        });
      }
    } catch (e) {
      setState(() => _caricamento = false);
    }
  }

  void _mostraDialogoLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Conferma Logout"),
        content: const Text("Sei sicuro di voler uscire dall'account Trainer?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Chiude il dialogo
              Navigator.pop(context); // Torna indietro dalla vista profilo
              widget.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Sì, esci",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvaModifiche() async {
    if (_nomeController.text.trim().isEmpty ||
        _cognomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compilare tutti i campi"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await DatabaseService.supabase
          .from('profiles')
          .update({
            'first_name': _nomeController.text.trim(),
            'last_name': _cognomeController.text.trim(),
          })
          .eq('id', widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profilo aggiornato con successo!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_caricamento) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.blue,
            size: 24,
          ),
          onPressed: widget.tornaHome,
        ),
        title: const Text(
          "PROFILO TRAINER",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // BOX CODICE TRAINER (Solo visualizzazione, no copia)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Text(
                      "IL TUO CODICE TRAINER",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codiceTrainer,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // CAMPI INPUT
              _buildTextField(
                "NOME",
                _nomeController,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                "COGNOME",
                _cognomeController,
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 12),
              const Text(
                "Gestisci i tuoi dati personali visibili agli atleti",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 40),

              // BOTTONI AZIONE
              _buildActionButton(
                "SALVA MODIFICHE",
                _salvaModifiche,
                Colors.blue,
                Icons.save_rounded,
              ),
              const SizedBox(height: 15),

              // BOTTONE LOGOUT (Sfondo rosso, testo bianco)
              _buildActionButton(
                "ESCI DALL'ACCOUNT",
                _mostraDialogoLogout,
                Colors.red,
                Icons.logout_rounded,
                textColor: Colors.white,
                isOutlined: false,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    Color color = Colors.blue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: color, size: 22)
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onPressed,
    Color color,
    IconData icon, {
    Color textColor = Colors.white,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor, size: 20),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    super.dispose();
  }
}
