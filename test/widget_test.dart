import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  // ── App smoke test
  testWidgets('App renders MenuScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    expect(find.text('GatoViralMx'), findsOneWidget);
    expect(find.text('Elige tu modo de juego'), findsOneWidget);
  });

  // ── Menu buttons present
  testWidgets('Menu shows all 4 game mode buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    expect(find.text('Modo Clásico'),   findsOneWidget);
    expect(find.text('Piezas Móviles'), findsOneWidget);
    expect(find.text('Super Gato 9×9'), findsOneWidget);
    expect(find.text('Gato Random'),    findsOneWidget);
  });

  // ── VS preview shows X and O
  testWidgets('Menu shows VS preview with X and O', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    expect(find.text('X'),        findsOneWidget);
    expect(find.text('O'),        findsOneWidget);
    expect(find.text('VS'),       findsOneWidget);
    expect(find.text('Azul Neón'),findsOneWidget);
    expect(find.text('Rojo Neón'),findsOneWidget);
  });

  // ── Navigate to SetupScreen (Clásico)
  testWidgets('Tapping Modo Clásico opens SetupScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    await tester.tap(find.text('Modo Clásico'));
    await tester.pumpAndSettle();

    expect(find.text('Clásico'),              findsOneWidget);
    expect(find.text('👥  2 Jugadores (Local)'), findsOneWidget);
    expect(find.text('Jugar vs Bot'),         findsOneWidget);
  });

  // ── Difficulty pills
  testWidgets('SetupScreen shows difficulty pills', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    await tester.tap(find.text('Modo Clásico'));
    await tester.pumpAndSettle();

    expect(find.text('Fácil'),   findsOneWidget);
    expect(find.text('Medio'),   findsOneWidget);
    expect(find.text('Difícil'), findsOneWidget);
  });

  // ── Navigate to GameScreen (PvP Classic)
  testWidgets('Tapping 2 Jugadores starts classic game', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    await tester.tap(find.text('Modo Clásico'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('👥  2 Jugadores (Local)'));
    await tester.pumpAndSettle();

    expect(find.text('Clásico'), findsOneWidget);
    expect(find.text('← Volver'), findsOneWidget);
  });

  // ── Score starts at 0
  testWidgets('Score starts at zero', (WidgetTester tester) async {
    await tester.pumpWidget(const GatoViralMxApp());
    await tester.pump();

    await tester.tap(find.text('Modo Clásico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('👥  2 Jugadores (Local)'));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsWidgets);
  });

  // ── GS unit tests
  group('GS (game state)', () {
    test('initial turn is X', () {
      final gs = GS(mode: GameMode.classic, opponent: Opponent.pvp, difficulty: Difficulty.medium);
      expect(gs.turn, 'X');
    });

    test('board starts empty', () {
      final gs = GS(mode: GameMode.classic, opponent: Opponent.pvp, difficulty: Difficulty.medium);
      expect(gs.board.every((c) => c == null), isTrue);
    });

    test('reset preserves score', () {
      final gs = GS(mode: GameMode.classic, opponent: Opponent.pvp, difficulty: Difficulty.medium);
      gs.score['X'] = 3;
      gs.reset();
      expect(gs.score['X'], 3);
      expect(gs.turn, 'X');
      expect(gs.board.every((c) => c == null), isTrue);
    });

    test('score map has X, O and draw keys', () {
      final gs = GS(mode: GameMode.classic, opponent: Opponent.pvp, difficulty: Difficulty.medium);
      expect(gs.score.containsKey('X'),    isTrue);
      expect(gs.score.containsKey('O'),    isTrue);
      expect(gs.score.containsKey('draw'), isTrue);
    });
  });

  // ── kWinCombos unit tests
  group('kWinCombos', () {
    test('contains 8 combos', () {
      expect(kWinCombos.length, 8);
    });

    test('each combo has 3 indices', () {
      for (final c in kWinCombos) {
        expect(c.length, 3);
      }
    });
  });

  // ── kAbilities unit tests
  group('kAbilities', () {
    test('contains 15 abilities', () {
      expect(kAbilities.length, 15);
    });

    test('all abilities have non-empty id and name', () {
      for (final a in kAbilities) {
        expect(a.id.isNotEmpty,   isTrue);
        expect(a.name.isNotEmpty, isTrue);
      }
    });

    test('non-auto abilities have a phase', () {
      for (final a in kAbilities) {
        if (!a.auto) expect(a.phase, isNotNull);
      }
    });
  });
}