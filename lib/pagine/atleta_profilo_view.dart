import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class AtletaProfiloView extends StatefulWidget {
  final String userId;

  final VoidCallback tornaHome;

  final VoidCallback logout;

  final Future<Map<String, dynamic>?> Function(String) getProfilo;

  final Future<bool> Function(String, String, String) updateProfilo;

  const AtletaProfiloView({
    super.key,

    required this.userId,

    required this.tornaHome,

    required this.logout,

    required this.getProfilo,

    required this.updateProfilo,
  });

  @override
  State<AtletaProfiloView> createState() => _AtletaProfiloViewState();
}

class _AtletaProfiloViewState extends State<AtletaProfiloView> {
  final TextEditingController _txtNome = TextEditingController();

  final TextEditingController _txtCognome = TextEditingController();

  final TextEditingController _txtPt = TextEditingController();

  String _codiceAtleta = "Caricamento...";

  String _errore = "";

  bool _isLoading = true;

  bool _hasPt = false;

  @override
  void initState() {
    super.initState();

    _caricaDati();
  }

  Future<void> _caricaDati() async {
    try {
      final profilo = await widget.getProfilo(widget.userId);

      if (profilo != null) {
        setState(() {
          _txtNome.text = profilo['first_name'] ?? "";

          _txtCognome.text = profilo['last_name'] ?? "";

          String ptName = profilo['trainer_name'] ?? "";

          if (ptName.isEmpty || ptName == "Non assegnato") {
            _txtPt.text = "Non assegnato";

            _hasPt = false;
          } else {
            _txtPt.text = ptName;

            _hasPt = true;
          }

          _codiceAtleta = profilo['unique_code'] ?? "N/D";

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errore = "Errore nel caricamento: $e";

        _isLoading = false;
      });
    }
  }

  void _copiaCodice() {
    if (_codiceAtleta != "N/D" && _codiceAtleta != "Caricamento...") {
      Clipboard.setData(ClipboardData(text: _codiceAtleta));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Codice $_codiceAtleta copiato!"),

          backgroundColor: Colors.blue,

          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _salvaModifiche() async {
    setState(() => _errore = "");

    if (_txtNome.text.trim().isEmpty || _txtCognome.text.trim().isEmpty) {
      setState(() => _errore = "Compilare i campi vuoti");

      return;
    }

    final successo = await widget.updateProfilo(
      widget.userId,

      _txtNome.text.trim(),

      _txtCognome.text.trim(),
    );

    if (successo && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profilo aggiornato con successo!"),

          backgroundColor: Colors.green,

          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _apriDialogoLogout() {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        title: const Text("Conferma Logout"),

        content: const Text("Sei sicuro di voler uscire dal tuo account?"),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
          ),

          ElevatedButton(
            onPressed: () {
              // 1. Chiude il popup

              Navigator.pop(context);

              // 2. Chiude la pagina profilo per tornare alla vista login/home gestita dal main

              Navigator.pop(context);

              // 3. Esegue la logica di logout (es. cancellazione sessione)

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          "PROFILO",

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

              // BOX CODICE
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),

                  borderRadius: BorderRadius.circular(15),

                  border: Border.all(color: Colors.blue.shade100),
                ),

                child: Column(
                  children: [
                    const Text(
                      "IL TUO CODICE ATLETA",

                      style: TextStyle(
                        fontSize: 11,

                        fontWeight: FontWeight.bold,

                        color: Colors.blueGrey,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Text(
                          _codiceAtleta,

                          style: const TextStyle(
                            fontSize: 22,

                            fontWeight: FontWeight.w900,

                            letterSpacing: 1.5,

                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 15),

                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,

                            color: Colors.blue,
                          ),

                          onPressed: _copiaCodice,

                          tooltip: "Copia codice",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_errore.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),

                  child: Text(
                    _errore,

                    style: const TextStyle(
                      color: Colors.red,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // CAMPI INPUT
              _buildTextField("NOME", _txtNome, icon: Icons.badge_outlined),

              const SizedBox(height: 20),

              _buildTextField(
                "COGNOME",

                _txtCognome,

                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 20),

              _buildTextField(
                "PERSONAL TRAINER",

                _txtPt,

                readOnly: true,

                icon: Icons.fitness_center,

                color: Colors.blueGrey,
              ),

              // MESSAGGIO DINAMICO PT
              Padding(
                padding: const EdgeInsets.only(top: 10),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      _hasPt
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,

                      size: 16,

                      color: _hasPt ? Colors.green : Colors.orange,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _hasPt
                          ? "PT associato correttamente"
                          : "Invia il codice al tuo PT per collegarti",

                      style: TextStyle(
                        fontSize: 13,

                        fontWeight: FontWeight.w600,

                        color: _hasPt ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
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

              // BOTTONE LOGOUT AGGIORNATO (SFONDO ROSSO, TESTO BIANCO)
              _buildActionButton(
                "ESCI DALL'ACCOUNT",

                _apriDialogoLogout,

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

    bool readOnly = false,

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

          readOnly: readOnly,

          style: const TextStyle(fontWeight: FontWeight.w600),

          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: color, size: 22)
                : null,

            filled: true,

            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,

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

      child: isOutlined
          ? OutlinedButton.icon(
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

              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ElevatedButton.icon(
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
}
