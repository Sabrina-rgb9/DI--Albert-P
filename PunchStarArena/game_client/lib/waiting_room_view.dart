import 'package:flutter/material.dart';

import 'app_data.dart';

class WaitingRoomView extends StatelessWidget {
  final AppData appData;

  const WaitingRoomView({super.key, required this.appData});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appData,
      builder: (BuildContext context, Widget? _) {
        return _WaitingRoomBody(appData: appData);
      },
    );
  }
}

class _WaitingRoomBody extends StatelessWidget {
  final AppData appData;

  const _WaitingRoomBody({required this.appData});

  @override
  Widget build(BuildContext context) {
    final int countdown = appData.countdownSeconds;
    final bool countingDown =
        countdown > 0 && appData.phase == MatchPhase.waiting;

    final List<MultiplayerPlayer> players =
        List<MultiplayerPlayer>.from(appData.players)
          ..sort(
            (MultiplayerPlayer a, MultiplayerPlayer b) =>
                a.joinOrder.compareTo(b.joinOrder),
          );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(0.05)
            ..scale(1.15),
          child: Image.asset(
            'assets/media/waiting_background.png',
            fit: BoxFit.cover,
          ),
        ),

        Container(color: Colors.black.withValues(alpha: 0.38)),

        Column(
          children: <Widget>[
            const SizedBox(height: 36),

        const Text(
          'Sala de espera',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w500,
            color: Color(0xFFF1F5F9),
            letterSpacing: 0.2,
            decoration: TextDecoration.none,
          ),
        ),

            const SizedBox(height: 16),

            SizedBox(
              height: 100,
              child: Center(
                child: countingDown
                    ? Text(
                        '$countdown',
                        style: const TextStyle(
                          fontSize: 74,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFFE2E8F0),
                          letterSpacing: 0,
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: _Panel(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Jugadores conectados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Expanded(
                          child: ListView.separated(
                            itemCount: players.length,
                            separatorBuilder:
                                (BuildContext ctx, int idx) =>
                                  Divider(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    height: 1,
                                  ),
                            itemBuilder: (BuildContext ctx, int idx) =>
                                _PlayerRow(
                              key: ValueKey<String>(players[idx].id),
                              player: players[idx],
                              isLocal: players[idx].id == appData.playerId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
    ),
      child: child,
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final MultiplayerPlayer player;
  final bool isLocal;

  const _PlayerRow({
    super.key,
    required this.player,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.person,
            color: isLocal
            ? const Color(0xFFE2E8F0)
            : Colors.white.withValues(alpha: 0.55),
                    size: 20,
                  ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                color: isLocal
                  ? const Color(0xFFF8FAFC)
                  : Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
              ),
            ),
          ),
          if (isLocal)
            const Text(
              '(tú)',
              style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w300,
              decoration: TextDecoration.none,
              ),
            ),
        ],
      ),
    );
  }
}