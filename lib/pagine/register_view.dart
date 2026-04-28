import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/style_config.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback vaiALogin;

  const RegisterView({super.key, required this.vaiALogin});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controller per i campi di testo
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confermaPassController = TextEditingController();

  String? _ruoloSelezionato;
  bool _accettoTermini = false;
  bool _obscureText = true;
  String _errorText = "";
  String _successText = "";

  // Funzione per mostrare il popup legale
  void _mostraTutelaLegale(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tutela Legale e Privacy"),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Informativa per l'utente:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "• L'utente dichiara di essere in possesso di certificato medico sportivo valido.\n"
                  "• L'esecuzione degli esercizi avviene sotto la propria responsabilità e controllo.\n"
                  "• I dati raccolti (Email, Nome, Carichi) sono trattati dal Dott. Bertolini esclusivamente per la gestione del piano di allenamento.\n"
                  "• Il Titolare non è responsabile per infortuni derivanti da un'esecuzione errata o da condizioni fisiche non dichiarate.\n"
                  "• È possibile richiedere la cancellazione dei dati in ogni momento.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ho capito"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eseguiRegistrazione() async {
    setState(() {
      _errorText = "";
      _successText = "";
    });

    // 1. Validazione campi obbligatori
    if (_emailController.text.isEmpty ||
        _passController.text.isEmpty ||
        _confermaPassController.text.isEmpty ||
        _nomeController.text.isEmpty ||
        _ruoloSelezionato == null) {
      setState(() {
        _errorText = "Compila tutti i campi obbligatori!";
      });
      return;
    }

    // 2. Controllo coincidenza password
    if (_passController.text != _confermaPassController.text) {
      setState(() {
        _errorText = "Le password non coincidono!";
      });
      return;
    }

    // 3. Controllo Checkbox Privacy
    if (!_accettoTermini) {
      setState(() {
        _errorText = "Devi accettare i termini e la privacy per continuare";
      });
      return;
    }

    try {
      final res = await DatabaseService.registraUtente(
        email: _emailController.text,
        password: _passController.text,
        nome: _nomeController.text,
        cognome: _cognomeController.text,
        ruolo: _ruoloSelezionato!,
        accettazioneTermini: _accettoTermini,
      );

      if (res != null) {
        setState(() {
          _successText = "Account creato con successo!";
          _errorText = "";
          // Svuota i campi
          _nomeController.clear();
          _cognomeController.clear();
          _emailController.clear();
          _passController.clear();
          _confermaPassController.clear();
          _ruoloSelezionato = null;
          _accettoTermini = false;
        });
      }
    } catch (ex) {
      String msgEx = ex.toString();
      setState(() {
        if (msgEx.contains("Password should be at least 6 characters")) {
          _errorText = "La password deve essere di almeno 6 caratteri";
        } else if (msgEx.contains("invalid format") ||
            msgEx.contains("Unable to validate email")) {
          _errorText = "Indirizzo email non valido";
        } else if (msgEx.toLowerCase().contains("already registered")) {
          _errorText = "Questa email è già registrata!";
        } else {
          _errorText = "Errore durante la registrazione";
        }
        _successText = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO GEK AL POSTO DELL'EMOJI
              Image.asset(
                'assets/images/Logo_Gek.png',
                height: 110, // Dimensione simile alla LoginView
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.edit_note,
                    size: 60,
                    color: Colors.grey,
                  );
                },
              ),
              const SizedBox(height: 10),
              const Text(
                "REGISTRAZIONE",
                style: TextStyle(
                  fontSize: StyleConfig.textSizeTitolo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Campi di input
              _buildField(_nomeController, "Nome"),
              const SizedBox(height: 10),
              _buildField(_cognomeController, "Cognome"),
              const SizedBox(height: 10),
              _buildField(
                _emailController,
                "Email",
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              // Campo Password
              _buildPasswordField(_passController, "Password"),
              const SizedBox(height: 10),

              // Campo Conferma Password
              _buildPasswordField(_confermaPassController, "Conferma Password"),
              const SizedBox(height: 10),

              // Dropdown Ruolo
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<String>(
                  value: _ruoloSelezionato,
                  decoration: StyleConfig.campoTestoDecoration(label: "Ruolo"),
                  items: const [
                    DropdownMenuItem(value: "atleta", child: Text("Atleta")),
                    DropdownMenuItem(value: "trainer", child: Text("Trainer")),
                  ],
                  onChanged: (val) => setState(() => _ruoloSelezionato = val),
                ),
              ),
              const SizedBox(height: 15),

              // SEZIONE CHECKBOX
              SizedBox(
                width: 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _accettoTermini,
                      activeColor: Colors.blue,
                      onChanged: (val) =>
                          setState(() => _accettoTermini = val ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          children: [
                            const Text(
                              "Accetto i Termini, la Privacy e dichiaro l'idoneità sportiva. ",
                              style: TextStyle(fontSize: 12),
                            ),
                            GestureDetector(
                              onTap: () => _mostraTutelaLegale(context),
                              child: const Text(
                                "(Leggi info)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Messaggi di stato
              if (_errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    _errorText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StyleConfig.colorErrore,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_successText.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    "Account creato con successo!",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Bottone CREA ACCOUNT
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _eseguiRegistrazione,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("CREA ACCOUNT"),
                ),
              ),

              TextButton(
                onPressed: widget.vaiALogin,
                child: const Text("Torna al Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget per i campi normali
  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: StyleConfig.campoTestoDecoration(label: label),
      ),
    );
  }

  // Widget specifico per le Password con l'occhiolino
  Widget _buildPasswordField(TextEditingController controller, String label) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: _obscureText,
        decoration: StyleConfig.campoTestoDecoration(label: label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}
