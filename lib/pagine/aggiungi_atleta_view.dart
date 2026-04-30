import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/style_config.dart';

class AggiungiAtletaView extends StatefulWidget {
  final VoidCallback vaiIndietro;

  const AggiungiAtletaView({super.key, required this.vaiIndietro});

  @override
  State<AggiungiAtletaView> createState() => _AggiungiAtletaViewState();
}

class _AggiungiAtletaViewState extends State<AggiungiAtletaView> {
  final TextEditingController _codiceController = TextEditingController();
  String _msgRisultato = "";
  Color _coloreMessaggio = Colors.red;
  bool _isLoading = false; // Per gestire il caricamento

  Future<void> _conferma() async {
    // 1. Pulizia iniziale e validazione locale
    String codice = _codiceController.text.trim();

    if (codice.isEmpty) {
      setState(() {
        _msgRisultato = "Inserisci un codice!";
        _coloreMessaggio = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _msgRisultato = "Verifica in corso...";
      _coloreMessaggio = Colors.blue;
    });

    try {
      // 2. Chiamata al servizio database
      final successo = await DatabaseService.collegaAtletaPerCodice(codice);

      if (successo) {
        setState(() {
          _msgRisultato = "Atleta collegato con successo!";
          _coloreMessaggio = Colors.green;
          _codiceController.clear();
        });
      } else {
        setState(() {
          _msgRisultato = "Codice errato o atleta già associato";
          _coloreMessaggio = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _msgRisultato = "Errore di connessione al server";
        _coloreMessaggio = Colors.red;
      });
    } finally {
      setState(() => _isLoading = false);
    }
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
                    "COLLEGAMENTO ATLETA",
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "AGGIUNGI ATLETA",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "Inserisci il codice univoco che l'atleta\nvisualizza nella sua Home:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),

              // Input Codice
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _codiceController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization
                      .characters, // Forza maiuscole sulla tastiera
                  enabled: !_isLoading, // Disabilita se sta caricando
                  decoration: StyleConfig.campoTestoDecoration(
                    label: "Codice Univoco Atleta",
                  ).copyWith(hintText: "Esempio: ABC123"),
                ),
              ),

              // Messaggio Risultato
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _msgRisultato,
                    key: ValueKey(_msgRisultato),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _coloreMessaggio,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Bottone Conferma
              SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _conferma, // Disabilita se in caricamento
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("CONFERMA COLLEGAMENTO"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
