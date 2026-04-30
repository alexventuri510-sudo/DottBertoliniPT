import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PtHomeView extends StatefulWidget {
  final String nome;
  final VoidCallback vaiAListaAtleti;
  final VoidCallback vaiAAggiungiAtleta;
  final VoidCallback vaiAProfilo;
  final VoidCallback vaiAPianiInScadenza;
  final VoidCallback logout;

  const PtHomeView({
    super.key,
    required this.nome,
    required this.vaiAListaAtleti,
    required this.vaiAAggiungiAtleta,
    required this.vaiAProfilo,
    required this.vaiAPianiInScadenza,
    required this.logout,
  });

  @override
  State<PtHomeView> createState() => _PtHomeViewState();
}

class _PtHomeViewState extends State<PtHomeView> {
  int pianiScadenzaCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaPianiInScadenza();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _caricaPianiInScadenza();
  }

  Future<void> _caricaPianiInScadenza() async {
    try {
      final piani = await DatabaseService.getPianiInScadenza();
      if (mounted) {
        setState(() {
          pianiScadenzaCount = piani.length;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight:
            100, // Altezza leggermente maggiore per ospitare l'header
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bentornato,",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Coach ${widget.nome}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.vaiAProfilo,
                    child: Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 3),
                        ),
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF1565C0),
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              "GESTIONE TEAM",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Colors.blueGrey,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 15),
            _buildDashboardCard(
              titolo: "Piani in Scadenza",
              sottotitolo: "Piani in scadenza: $pianiScadenzaCount",
              icona: Icons.notification_important_rounded,
              colore: Colors.orange.shade700,
              azione: widget.vaiAPianiInScadenza,
            ),
            const SizedBox(height: 15),
            _buildDashboardCard(
              titolo: "I tuoi Atleti",
              sottotitolo: "Gestisci schede e progressi",
              icona: Icons.groups_rounded,
              colore: Colors.black,
              azione: widget.vaiAListaAtleti,
            ),
            const SizedBox(height: 15),
            _buildDashboardCard(
              titolo: "Nuovo Atleta",
              sottotitolo: "Crea account e assegna piani",
              icona: Icons.person_add_alt_1_rounded,
              colore: Colors.grey.shade800,
              azione: widget.vaiAAggiungiAtleta,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String titolo,
    required String sottotitolo,
    required IconData icona,
    required Color colore,
    required VoidCallback azione,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: azione,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colore,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icona, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titolo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        sottotitolo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
