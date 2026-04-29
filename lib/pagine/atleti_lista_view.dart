import 'package:flutter/material.dart';

import '../services/database_service.dart';

class AtletiListaView extends StatefulWidget {
  final VoidCallback vaiIndietro;

  final Function(String id, String nome) vaiAPianiAtleta;

  const AtletiListaView({
    super.key,

    required this.vaiIndietro,

    required this.vaiAPianiAtleta,
  });

  @override
  State<AtletiListaView> createState() => _AtletiListaViewState();
}

class _AtletiListaViewState extends State<AtletiListaView> {
  late Future<List<dynamic>> _futureAtleti;

  @override
  void initState() {
    super.initState();

    _caricaAtleti();
  }

  void _caricaAtleti() {
    setState(() {
      _futureAtleti = DatabaseService.getAtletiCollegati().then((lista) {
        lista.sort((a, b) {
          String nomeA = (a['first_name'] ?? '').toString().toLowerCase();

          String nomeB = (b['first_name'] ?? '').toString().toLowerCase();

          return nomeA.compareTo(nomeB);
        });

        return lista;
      });
    });
  }

  void _confermaScollegamento(String atletaId, String nomeAtleta) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        title: const Text("Scollega Atleta"),

        content: Text(
          "Sei sicuro di voler scollegare $nomeAtleta? Non vedrai più i suoi piani, ma i dati rimarranno salvati.",
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            onPressed: () async {
              Navigator.pop(context);

              final success = await DatabaseService.scollegaAtleta(atletaId);

              if (success) {
                await Future.delayed(const Duration(milliseconds: 300));

                _caricaAtleti();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Atleta $nomeAtleta scollegato")),
                  );
                }
              }
            },

            child: const Text(
              "Sì, scollega",

              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,

            color: Colors.black,

            size: 20,
          ),

          onPressed: widget.vaiIndietro,
        ),

        title: const Text(
          "I MIEI ATLETI",

          style: TextStyle(
            fontWeight: FontWeight.w900,

            color: Colors.black,

            fontSize: 18,

            letterSpacing: 1.2,
          ),
        ),

        centerTitle: true,

        backgroundColor: Colors.white,

        elevation: 0.5,
      ),

      body: FutureBuilder<List<dynamic>>(
        future: _futureAtleti,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Errore nel caricamento"));
          }

          final atleti = snapshot.data ?? [];

          if (atleti.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.people_outline,

                    size: 80,

                    color: Colors.grey.shade300,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Nessun atleta in lista",

                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.black,

            onRefresh: () async => _caricaAtleti(),

            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

              itemCount: atleti.length,

              itemBuilder: (context, index) {
                final a = atleti[index];

                final nome = a['first_name'] ?? 'Utente';

                final cognome = a['last_name'] ?? '';

                final nomeCompleto = "$nome $cognome";

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(16),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),

                        blurRadius: 10,

                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(12),

                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,

                          backgroundColor: Colors.blue.shade50,

                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : "?",

                            style: TextStyle(
                              color: Colors.blue.shade700,

                              fontWeight: FontWeight.bold,

                              fontSize: 18,
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Text(
                            nomeCompleto.toUpperCase(),

                            style: const TextStyle(
                              fontWeight: FontWeight.bold,

                              fontSize: 15,
                            ),

                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => widget.vaiAPianiAtleta(
                                a['id'].toString(),

                                nomeCompleto,
                              ),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,

                                foregroundColor: Colors.white,

                                elevation: 0,

                                minimumSize: const Size(90, 32),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              child: const Text(
                                "GESTISCI",

                                style: TextStyle(
                                  fontSize: 11,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            ElevatedButton(
                              onPressed: () => _confermaScollegamento(
                                a['id'].toString(),

                                nomeCompleto,
                              ),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,

                                foregroundColor: Colors.white,

                                elevation: 0,

                                minimumSize: const Size(90, 32),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              child: const Text(
                                "SCOLLEGA",

                                style: TextStyle(
                                  fontSize: 11,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
