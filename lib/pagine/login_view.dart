import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/style_config.dart';

class LoginView extends StatefulWidget {
  final Function(String ruolo, String nome) loginSuccesso;
  final VoidCallback vaiARegistrazione;
  final VoidCallback vaiARecupero;

  const LoginView({
    super.key,
    required this.loginSuccesso,
    required this.vaiARegistrazione,
    required this.vaiARecupero,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String _errorText = "";
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _clickAccedi() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _errorText = "";
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = "Inserisci tutte le credenziali.";
        _isLoading = false;
      });
      return;
    }

    try {
      debugPrint("DEBUG: Tentativo di login per: $email");

      final profilo = await DatabaseService.loginUtente(email, password);

      if (!mounted) return;

      if (profilo != null) {
        debugPrint("DEBUG: Login ok. Profilo: ${profilo['first_name']}");

        final String ruolo = profilo['role']?.toString() ?? 'atleta';
        final String nome = profilo['first_name']?.toString() ?? 'Utente';

        widget.loginSuccesso(ruolo, nome);
      } else {
        setState(() {
          _errorText = "Credenziali non valide o profilo mancante.";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("DEBUG: Eccezione LoginView: $e");
      if (mounted) {
        setState(() {
          _errorText = "Errore di connessione. Riprova.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO GEK AL POSTO DELL'EMOJI
                    Image.asset(
                      'assets/images/Logo_Gek.png',
                      height: 120, // Altezza bilanciata per il login
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Ritorna un'icona di fallback se l'immagine non viene caricata
                        return const Icon(
                          Icons.fitness_center,
                          size: 70,
                          color: Colors.grey,
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "DottBertoliniPT",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Campo Email
                    TextField(
                      controller: _emailController,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isLoading,
                      decoration:
                          StyleConfig.campoTestoDecoration(
                            label: "Email",
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 22,
                            ),
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Password
                    TextField(
                      controller: _passController,
                      obscureText: _obscureText,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _clickAccedi(),
                      decoration:
                          StyleConfig.campoTestoDecoration(
                            label: "Password",
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 22,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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

                    if (_errorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          _errorText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 35),

                    // Bottone Accedi
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _clickAccedi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "ACCEDI",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Password dimenticata
                    TextButton(
                      onPressed: _isLoading ? null : widget.vaiARecupero,
                      child: const Text(
                        "Hai dimenticato la password?",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Colors.black12),
                    ),

                    // Footer Registrazione
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Nuovo sull'App?"),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : widget.vaiARegistrazione,
                          child: const Text(
                            "Crea un account",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
