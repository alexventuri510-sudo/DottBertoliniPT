import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/database_service.dart';

// --- AGGIUNTI PER LOCALIZZAZIONE ITALIANA ---
import 'package:flutter_localizations/flutter_localizations.dart';

// --- IMPORT VISTE ---
import 'pagine/login_view.dart';
import 'pagine/register_view.dart';
import 'pagine/recupero_password_view.dart';
import 'pagine/nuova_password_view.dart';
import 'pagine/pt_home_view.dart';
import 'pagine/pt_profilo_view.dart';
import 'pagine/aggiungi_atleta_view.dart';
import 'pagine/atleti_lista_view.dart';
import 'pagine/piani_allenamento_view.dart';
import 'pagine/crea_piano_view.dart';
import 'pagine/esercizi_lista_view.dart';
import 'pagine/aggiungi_esercizio_view.dart';
import 'pagine/modifica_esercizio_view.dart';
import 'pagine/dettaglio_esercizio_view.dart';
import 'pagine/atleta_home_view.dart';
import 'pagine/atleta_piani_view.dart';
import 'pagine/atleta_pianox_view.dart';
import 'pagine/atleta_dettaglio_esercizio_view.dart';
import 'pagine/atleta_modifica_dettaglio_esercizio_view.dart';
import 'pagine/atleta_profilo_view.dart';
import 'pagine/atleta_lista_esercizi_view.dart';
import 'pagine/pt_piani_in_scadenza_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BLOCCO ORIENTAMENTO IN VERTICALE
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Supabase.initialize(
      url: 'https://zxnxnsjuvgtliydvtuop.supabase.co',
      anonKey: 'sb_publishable_B2_48nFeC4rqa12sMPYWLQ_v31dRxO9',
    );
  } catch (e) {
    debugPrint("Errore Init Supabase: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _schermataAttuale;

  @override
  void initState() {
    super.initState();
    _checkAuthIniziale();
    _ascoltaRecuperoPassword();
  }

  void _ascoltaRecuperoPassword() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => NuovaPasswordView(vaiALogin: _impostaLogin),
          ),
          (route) => false,
        );
      }
    });
  }

  Future<void> _checkAuthIniziale() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final session = Supabase.instance.client.auth.currentSession;

    if (Uri.base.toString().contains('type=recovery')) {
      return;
    }

    if (session == null) {
      _impostaLogin();
    } else {
      try {
        final profilo = await DatabaseService.getProfiloCompleto(
          session.user.id,
        );
        if (profilo != null) {
          _impostaHome(
            profilo['role'] ?? 'atleta',
            profilo['first_name'] ?? 'Utente',
            session.user.id,
            profilo['unique_code'] ?? '',
          );
        } else {
          _impostaLogin();
        }
      } catch (e) {
        _impostaLogin();
      }
    }
  }

  void _eseguiLogout() async {
    await DatabaseService.logoutUtente();
    _impostaLogin();
  }

  void _impostaLogin() {
    setState(() {
      _schermataAttuale = LoginView(
        loginSuccesso: (ruolo, nome) {
          final uid = Supabase.instance.client.auth.currentUser?.id ?? "";
          _impostaHome(ruolo, nome, uid, "");
        },
        vaiARegistrazione: () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => RegisterView(
                vaiALogin: () => navigatorKey.currentState?.pop(),
              ),
            ),
          );
        },
        vaiARecupero: () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => RecuperoPasswordView(
                vaiALogin: () => navigatorKey.currentState?.pop(),
              ),
            ),
          );
        },
      );
    });
  }

  void _impostaHome(
    String ruolo,
    String nome,
    String userId, [
    String codice = "",
  ]) {
    setState(() {
      if (ruolo == 'trainer') {
        _schermataAttuale = PtHomeView(
          nome: nome,
          vaiAListaAtleti: _navigaAListaAtleti,
          vaiAAggiungiAtleta: _navigaAAggiungiAtleta,
          vaiAProfilo: () => _navigaAProfiloTrainer(userId),
          vaiAPianiInScadenza: _navigaAPianiInScadenza,
          logout: _eseguiLogout,
        );
      } else {
        _schermataAttuale = AtletaHomeView(
          nome: nome,
          codice: codice,
          logout: _eseguiLogout,
          vaiAPianiPersonali: () => _navigaAPianiAtleta(userId, nome),
          vaiAProfilo: () => _navigaAProfiloAtleta(userId),
          vaiAEsercizi: (piano, nomeA, sett, dataStr) =>
              _navigaAPianoX(piano, nomeA, sett, dataStr),
        );
      }
    });
  }

  // --- NAVIGAZIONE PT ---
  void _navigaAPianiInScadenza() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const PtPianiInScadenzaView()),
    );
  }

  void _navigaAListaAtleti() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AtletiListaView(
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          vaiAPianiAtleta: _navigaAPianiGestioneTrainer,
        ),
      ),
    );
  }

  void _navigaAAggiungiAtleta() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AggiungiAtletaView(
          vaiIndietro: () => navigatorKey.currentState?.pop(),
        ),
      ),
    );
  }

  void _navigaAProfiloTrainer(String userId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => PtProfiloView(
          userId: userId,
          tornaHome: () => navigatorKey.currentState?.pop(),
          logout: _eseguiLogout,
        ),
      ),
    );
  }

  void _navigaAPianiGestioneTrainer(String idAtleta, String nomeAtleta) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => PianiAllenamentoView(
          atletaId: idAtleta,
          nomeAtleta: nomeAtleta,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          vaiACreaPiano: (id, n) => _navigaACreaPiano(id, n),
          vaiAListaEsercizi: (piano) => _navigaAListaEsercizi(piano),
        ),
      ),
    );
  }

  void _navigaACreaPiano(String id, String n) async {
    await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => CreaPianoView(
          atletaId: id,
          nomeAtleta: n,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
        ),
      ),
    );
  }

  void _navigaAListaEsercizi(Map<String, dynamic> piano) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => EserciziListaView(
          planId: piano['id'].toString(),
          durataSettimane: piano['duration_weeks'] ?? 1,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          vaiAAggiungiEsercizio: _navigaAAggiungiEsercizio,
          vaiADettaglio: (lista, indice, sett) =>
              _navigaADettaglioEsercizioTrainer(lista, indice),
          vaiAModifica: (esercizio, sett) =>
              _navigaAModificaEsercizio(esercizio),
        ),
      ),
    );
  }

  void _navigaAAggiungiEsercizio(String planId, int weekNumber) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AggiungiEsercizioView(
          planId: planId,
          weekNumber: weekNumber,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
        ),
      ),
    );
  }

  void _navigaAModificaEsercizio(Map<String, dynamic> datiEsercizio) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ModificaEsercizioView(
          datiEsercizio: datiEsercizio,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
        ),
      ),
    );
  }

  void _navigaADettaglioEsercizioTrainer(List<dynamic> lista, int indice) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DettaglioEsercizioView(
          listaEsercizi: lista,
          indiceAttuale: indice,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          cambiaEsercizio: (nuovoIndice) {
            navigatorKey.currentState?.pop();
            _navigaADettaglioEsercizioTrainer(lista, nuovoIndice);
          },
        ),
      ),
    );
  }

  // --- NAVIGAZIONE ATLETA ---
  void _navigaAPianiAtleta(String userId, String nome) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AtletaPianiView(
          atletaId: userId,
          nomeAtleta: nome,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          vaiAListaEsercizi: (piano, nomeA, sett) =>
              _navigaAListaEserciziAtleta(piano, nomeA, sett),
        ),
      ),
    );
  }

  void _navigaAListaEserciziAtleta(
    Map<String, dynamic> piano,
    String nomeAtleta,
    int settimanaIniziale,
  ) {
    // RECUPERO DEL GIORNO DALLA MAPPA DEL PIANO
    final String giorno = piano['day_of_week'] ?? "Allenamento";

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AtletaListaEserciziView(
          planId: piano['id'].toString(),
          nomeAtleta: nomeAtleta,
          giornoSettimana: giorno, // PASSAGGIO DEL GIORNO DINAMICO
          durataSettimane: piano['duration_weeks'] ?? 1,
          settimanaIniziale: settimanaIniziale,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          vaiADettaglioEsercizio: (lista, indice, sett) =>
              _navigaADettaglioSolaLetturaAtleta(lista, indice),
        ),
      ),
    );
  }

  void _navigaAProfiloAtleta(String userId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AtletaProfiloView(
          userId: userId,
          getProfilo: DatabaseService.getProfiloCompleto,
          updateProfilo: DatabaseService.updateProfilo,
          tornaHome: () => navigatorKey.currentState?.pop(),
          logout: _eseguiLogout,
        ),
      ),
    );
  }

  void _navigaAPianoX(
    Map<String, dynamic> piano,
    String nomeAtleta,
    int settimana,
    String dataStr,
  ) async {
    await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AtletaPianoXView(
          planId: piano['id'].toString(),
          settimana: settimana,
          nomeAtleta: nomeAtleta,
          dataPianoStr: dataStr,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          vaiADettaglioEsercizio: (lista, indice, sett) async {
            final result = await _navigaAModificaDettaglioAtleta(lista, indice);
            return result ?? false;
          },
        ),
      ),
    );
  }

  Future<bool?> _navigaAModificaDettaglioAtleta(
    List<dynamic> lista,
    int indice,
  ) async {
    return await navigatorKey.currentState?.push<bool>(
      MaterialPageRoute(
        builder: (context) => AtletaModificaDettaglioEsercizioView(
          listaEsercizi: lista,
          indiceAttuale: indice,
          vaiIndietro: () => navigatorKey.currentState?.pop(true),
          salvaDati: (id, pesi, reps, note) async {
            await DatabaseService.updateDatiAllenamentoAtleta(
              id,
              pesi,
              reps,
              note,
            );
          },
          cambiaEsercizio: (nuovoIndice) {},
        ),
      ),
    );
  }

  void _navigaADettaglioSolaLetturaAtleta(List<dynamic> lista, int indice) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AtletaDettaglioEsercizioView(
          listaEsercizi: lista,
          indiceAttuale: indice,
          vaiIndietro: () => navigatorKey.currentState?.pop(),
          cambiaEsercizio: (nuovoIndice) {
            navigatorKey.currentState?.pop();
            _navigaADettaglioSolaLetturaAtleta(lista, nuovoIndice);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DottBertoliniPT',
      debugShowCheckedModeBanner: false,

      // --- CONFIGURAZIONE LOCALIZZAZIONE ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'), // Italiano
      ],

      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home:
          _schermataAttuale ??
          const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          ),
    );
  }
}
