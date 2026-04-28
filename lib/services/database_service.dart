import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final supabase = Supabase.instance.client;

  // --- LOGICA CODICE UNIVOCO ---
  static String generaCodice({int lunghezza = 6}) {
    const caratteri = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        lunghezza,
        (_) => caratteri.codeUnitAt(rnd.nextInt(caratteri.length)),
      ),
    );
  }

  // --- AUTENTICAZIONE ---
  static Future<Map<String, dynamic>?> loginUtente(
    String email,
    String password,
  ) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) return await getProfiloCompleto(res.user!.id);
      return null;
    } catch (e) {
      debugPrint("DEBUG: Errore Auth Login: $e");
      return null;
    }
  }

  static Future<void> logoutUtente() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint("DEBUG: Errore Logout: $e");
    }
  }

  // --- REGISTRAZIONE AGGIORNATA CON PRIVACY ---
  static Future<String?> registraUtente({
    required String email,
    required String password,
    required String nome,
    required String cognome,
    required String ruolo,
    required bool accettazioneTermini,
  }) async {
    try {
      final resAuth = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (resAuth.user != null) {
        String codice = generaCodice();
        await supabase.from('profiles').insert({
          'id': resAuth.user!.id,
          'first_name': nome,
          'last_name': cognome,
          'email': email,
          'role': ruolo,
          'unique_code': codice,
          'accettazione_termini': accettazioneTermini,
          'data_accettazione': DateTime.now().toIso8601String(),
        });
        return codice;
      }
      return null;
    } catch (e) {
      debugPrint("DEBUG: Errore Registrazione: $e");
      rethrow;
    }
  }

  // --- GESTIONE PROFILO ---
  static Future<Map<String, dynamic>?> getProfiloCompleto(String userId) async {
    try {
      final profilo = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (profilo == null) return null;

      if (profilo['associated_trainer_id'] != null) {
        final trainerRes = await supabase
            .from('profiles')
            .select('first_name, last_name')
            .eq('id', profilo['associated_trainer_id'])
            .maybeSingle();

        if (trainerRes != null) {
          profilo['trainer_name'] =
              "${trainerRes['first_name'] ?? ''} ${trainerRes['last_name'] ?? ''}"
                  .trim();
        }
      } else {
        profilo['trainer_name'] = "Non assegnato";
      }
      return profilo;
    } catch (e) {
      debugPrint("DEBUG: Errore recupero profilo: $e");
      return null;
    }
  }

  static Future<bool> updateProfilo(
    String userId,
    String nome,
    String cognome,
  ) async {
    try {
      await supabase
          .from('profiles')
          .update({'first_name': nome, 'last_name': cognome})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- GESTIONE ATLETI (LATO TRAINER) ---
  static Future<List<dynamic>> getAtletiCollegati() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      return await supabase
          .from('profiles')
          .select(
            'id, first_name, last_name, unique_code, associated_trainer_id',
          )
          .eq('associated_trainer_id', userId)
          .order('first_name');
    } catch (e) {
      debugPrint("DEBUG: Errore getAtletiCollegati: $e");
      return [];
    }
  }

  static Future<bool> collegaAtletaPerCodice(String codice) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final codicePulito = codice.trim().toUpperCase();

      final res = await supabase
          .from('profiles')
          .update({'associated_trainer_id': userId})
          .eq('unique_code', codicePulito)
          .select();

      return res.isNotEmpty;
    } catch (e) {
      debugPrint("DEBUG: Errore collegamento atleta: $e");
      return false;
    }
  }

  static Future<bool> scollegaAtleta(String atletaId) async {
    try {
      final res = await supabase
          .from('profiles')
          .update({'associated_trainer_id': null})
          .eq('id', atletaId)
          .select();
      return res.isNotEmpty;
    } catch (e) {
      debugPrint("DEBUG: Errore scollegaAtleta: $e");
      return false;
    }
  }

  // --- GESTIONE PIANI ALLENAMENTO ---
  static Future<List<dynamic>> getPianiAtleta(String atletaId) async {
    try {
      return await supabase
          .from('workout_plans')
          .select()
          .eq('client_id', atletaId)
          .order('start_date', ascending: false);
    } catch (e) {
      return [];
    }
  }

  // --- FUNZIONE PIANI IN SCADENZA (NOVITÀ) ---
  static Future<List<Map<String, dynamic>>> getPianiInScadenza() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Recuperiamo i piani con le info dell'atleta (profiles)
      final response = await supabase
          .from('workout_plans')
          .select(
            '*, profiles!workout_plans_client_id_fkey(first_name, last_name)',
          )
          .eq('trainer_id', userId);

      final List<Map<String, dynamic>> inScadenza = [];
      final DateTime oggi = DateTime.now();
      final DateTime oggiSoloData = DateTime(oggi.year, oggi.month, oggi.day);

      for (var p in response) {
        DateTime startDate = DateTime.parse(p['start_date']);
        int durataTotale = p['duration_weeks'] ?? 0;

        int giorniPassati = oggiSoloData.difference(startDate).inDays;
        int settimanaAttuale = (giorniPassati ~/ 7) + 1;

        // Un piano è in scadenza se siamo esattamente nell'ultima settimana
        if (settimanaAttuale == durataTotale) {
          inScadenza.add({
            ...p,
            'settimana_attuale': settimanaAttuale,
            'nome_atleta':
                "${p['profiles']['first_name']} ${p['profiles']['last_name']}",
          });
        }
      }
      return inScadenza;
    } catch (e) {
      debugPrint("DEBUG: Errore getPianiInScadenza: $e");
      return [];
    }
  }

  static Future<bool> creaPianoAllenamento({
    required String atletaId,
    required String giornoSettimana,
    required int durataSettimane,
    required String startDate,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('workout_plans').insert({
        'client_id': atletaId,
        'trainer_id': userId,
        'day_of_week': giornoSettimana,
        'duration_weeks': durataSettimane,
        'start_date': startDate,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> eliminaPianoAllenamento(String planId) async {
    try {
      await supabase.from('workout_plans').delete().eq('id', planId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- GESTIONE ESERCIZI ---
  static Future<List<dynamic>> getEserciziPiano(
    String planId,
    int weekNumber,
  ) async {
    try {
      final response = await supabase
          .from('exercises')
          .select()
          .eq('plan_id', planId)
          .eq('week_number', weekNumber)
          .order('exercise_order', ascending: true);

      final List<dynamic> lista = List<Map<String, dynamic>>.from(response);

      if (weekNumber > 1) {
        for (var ex in lista) {
          final prec = await supabase
              .from('exercises')
              .select('series_weights_atleta')
              .eq('plan_id', planId)
              .eq('week_number', weekNumber - 1)
              .eq('exercise_name', ex['exercise_name'])
              .maybeSingle();

          ex['series_weights_scorsi'] = prec != null
              ? prec['series_weights_atleta']
              : "";
        }
      }
      return lista;
    } catch (e) {
      return [];
    }
  }

  static Future<void> eliminaEsercizio(String id) async {
    try {
      await supabase.from('exercises').delete().eq('id', id);
    } catch (e) {
      debugPrint("DEBUG: Errore eliminazione esercizio: $e");
    }
  }

  static Future<void> spostaEsercizio(String id, int nuovoOrdine) async {
    try {
      await supabase
          .from('exercises')
          .update({'exercise_order': nuovoOrdine})
          .eq('id', id);
    } catch (e) {
      debugPrint("DEBUG: Errore spostamento esercizio: $e");
    }
  }

  static Future<bool> aggiungiEsercizio({
    required String planId,
    required String exerciseName,
    required String setsReps,
    required int restSeconds,
    required String trainerNotes,
    required String videoLink,
    required int weekNumber,
    required int exerciseOrder,
    required int seriesCount,
  }) async {
    try {
      await supabase.from('exercises').insert({
        'plan_id': planId,
        'exercise_name': exerciseName,
        'sets_reps': setsReps,
        'rest_seconds': restSeconds,
        'trainer_notes': trainerNotes,
        'video_link': videoLink,
        'week_number': weekNumber,
        'exercise_order': exerciseOrder,
        'series_count': seriesCount,
      });
      return true;
    } catch (e) {
      debugPrint("DEBUG: Errore aggiungiEsercizio: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> copiaSettimanaUno(
    String planId,
    int durataSettimane,
  ) async {
    try {
      final eserciziSett1 = await getEserciziPiano(planId, 1);
      if (eserciziSett1.isEmpty) {
        return {'success': false, 'msg': 'Settimana 1 vuota'};
      }

      for (int w = 2; w <= durataSettimane; w++) {
        await supabase
            .from('exercises')
            .delete()
            .eq('plan_id', planId)
            .eq('week_number', w);

        final nuoviEsercizi = eserciziSett1.map((e) {
          final n = Map<String, dynamic>.from(e);
          n.remove('id');
          n.remove('created_at');
          if (n.containsKey('updated_at')) n.remove('updated_at');
          n['week_number'] = w;
          n['series_weights_atleta'] = '';
          n['series_reps_atleta'] = '';
          n['athlete_notes'] = '';
          return n;
        }).toList();

        await supabase.from('exercises').insert(nuoviEsercizi);
      }
      return {'success': true, 'msg': 'Programma generato!'};
    } catch (e) {
      debugPrint("DEBUG: Errore copiaSettimanaUno: $e");
      return {'success': false, 'msg': 'Errore copia'};
    }
  }

  static Future<void> updateDatiAllenamentoAtleta(
    String exerciseId,
    List<String> weights,
    List<String> reps,
    String athleteNotes,
  ) async {
    try {
      final String weightsStr = weights.map((w) => w.trim()).join(',');
      final String repsStr = reps.map((r) => r.trim()).join(',');

      await supabase
          .from('exercises')
          .update({
            'series_weights_atleta': weightsStr,
            'series_reps_atleta': repsStr,
            'athlete_notes': athleteNotes.trim(),
          })
          .eq('id', exerciseId);

      debugPrint("DEBUG: Database aggiornato per esercizio $exerciseId");
    } catch (e) {
      debugPrint("DEBUG: Errore updateDatiAllenamentoAtleta: $e");
    }
  }

  static Future<bool> aggiornaProgressiMultiSerie(
    String exerciseId,
    List<dynamic> listaPesi,
    List<dynamic> listaReps,
    String noteAtleta,
  ) async {
    try {
      await updateDatiAllenamentoAtleta(
        exerciseId,
        listaPesi.map((e) => e.toString()).toList(),
        listaReps.map((e) => e.toString()).toList(),
        noteAtleta,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
