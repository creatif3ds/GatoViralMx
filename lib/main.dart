import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GatoViralMxApp());
}

// ══════════════════════════════════════════
//  COLORS
// ══════════════════════════════════════════
const kBg    = Color(0xFF07090F);
const kCard  = Color(0xFF0D1220);
const kCell  = Color(0xFF101828);
const kText  = Color(0xFFE0E6F0);
const kCyan  = Color(0xFF00E5FF);
const kRed   = Color(0xFFFF2D6B);
const kOrange= Color(0xFFFF8C00);
const kPurple= Color(0xFFA855F7);
const kGreen = Color(0xFF00C97A);
const kMuted = Color(0x59FFFFFF);

// ══════════════════════════════════════════
//  ENUMS
// ══════════════════════════════════════════
enum GameMode   { classic, wild, superMode, random }
enum Opponent   { pvp, bot }
enum Difficulty { easy, medium, hard }

// ══════════════════════════════════════════
//  ABILITY MODEL
// ══════════════════════════════════════════
class Ability {
  final String id, name, icon, desc;
  final Color  color;
  final bool   auto;
  final String? phase;
  const Ability({
    required this.id, required this.name, required this.icon,
    required this.desc, required this.color, required this.auto, this.phase,
  });
}

const kAbilities = <Ability>[
  Ability(id:'xline',        name:'X Line',          icon:'✕',  color:Color(0xFFFF6B35), auto:true,  desc:'Tu símbolo conquista las esquinas y el centro, eliminando al rival.'),
  Ability(id:'maldicion',    name:'Maldición',        icon:'💀', color:Color(0xFF9B59B6), auto:true,  desc:'¡El rival pierde su próximo turno!'),
  Ability(id:'bomba',        name:'Bomba',             icon:'💣', color:Color(0xFFE74C3C), auto:true,  desc:'¡BOOM! Destruye hasta 4 fichas al azar del tablero.'),
  Ability(id:'caos_total',   name:'Caos Total',        icon:'🌀', color:Color(0xFFF39C12), auto:true,  desc:'¡Todas las fichas son redistribuidas aleatoriamente!'),
  Ability(id:'rayo',         name:'Rayo',              icon:'⚡', color:Color(0xFFF1C40F), auto:true,  desc:'Un rayo destruye 2 fichas del rival.'),
  Ability(id:'linea_simple', name:'Línea Simple',      icon:'📏', color:kCyan,             auto:false, phase:'line_select', desc:'Elige una fila, columna o diagonal y llénatela con tu símbolo.'),
  Ability(id:'robo',         name:'Robo de Ficha',     icon:'🎭', color:Color(0xFF2ECC71), auto:false, phase:'steal',       desc:'Convierte una ficha del rival en tuya.'),
  Ability(id:'teletransporte',name:'Teletransporte',   icon:'🔮', color:Color(0xFF3498DB), auto:false, phase:'teleport_from',desc:'Mueve una de tus fichas a cualquier casilla vacía.'),
  Ability(id:'doble_turno',  name:'Doble Turno',       icon:'🎯', color:Color(0xFF1ABC9C), auto:true,  desc:'¡Coloca DOS fichas normales este turno!'),
  Ability(id:'borrador',     name:'Borrador',          icon:'🧹', color:Color(0xFF95A5A6), auto:false, phase:'erase',       desc:'Elimina cualquier ficha del tablero.'),
  Ability(id:'escudo',       name:'Escudo Arcano',     icon:'🛡️', color:Color(0xFF27AE60), auto:true,  desc:'Tus fichas son inmunes a la próxima habilidad del rival.'),
  Ability(id:'invasion',     name:'Invasión',          icon:'👾', color:Color(0xFFE91E63), auto:true,  desc:'Tu símbolo aparece en 2 casillas vacías aleatorias.'),
  Ability(id:'congelar',     name:'Congelación',       icon:'🧊', color:Color(0xFF74B9FF), auto:true,  desc:'Limpias el escudo del rival y lo maldices.'),
  Ability(id:'inversion',    name:'Inversión',         icon:'🔄', color:Color(0xFFFD79A8), auto:true,  desc:'Todas las X pasan a O y viceversa.'),
  Ability(id:'duplicar',     name:'Duplicar',          icon:'✨', color:Color(0xFFA29BFE), auto:true,  desc:'Copia una de tus fichas en una casilla adyacente aleatoria.'),
];

// ══════════════════════════════════════════
//  WIN COMBOS & LINE DEFS
// ══════════════════════════════════════════
const kWinCombos = [
  [0,1,2],[3,4,5],[6,7,8],
  [0,3,6],[1,4,7],[2,5,8],
  [0,4,8],[2,4,6],
];

const kLineDefs = [
  {'label':'↔ Fila 1', 'i':[0,1,2]},
  {'label':'↔ Fila 2', 'i':[3,4,5]},
  {'label':'↔ Fila 3', 'i':[6,7,8]},
  {'label':'↕ Col. 1', 'i':[0,3,6]},
  {'label':'↕ Col. 2', 'i':[1,4,7]},
  {'label':'↕ Col. 3', 'i':[2,5,8]},
  {'label':'↘ Diag',   'i':[0,4,8]},
  {'label':'↗ Diag',   'i':[2,4,6]},
];

// ══════════════════════════════════════════
//  APP
// ══════════════════════════════════════════
class GatoViralMxApp extends StatelessWidget {
  const GatoViralMxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GatoViralMx',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'sans-serif',
      ),
      home: const MenuScreen(),
    );
  }
}

// ══════════════════════════════════════════
//  MENU SCREEN
// ══════════════════════════════════════════
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override State<MenuScreen> createState() => _MenuScreenState();
}
class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logo;

  @override void initState() {
    super.initState();
    _logo = AnimationController(vsync:this, duration:const Duration(seconds:3))..repeat();
  }
  @override void dispose() { _logo.dispose(); super.dispose(); }

  void _go(GameMode m) => Navigator.push(context, _slide(SetupScreen(mode:m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth:480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal:20, vertical:20),
          child: Column(children:[
            // ── Logo
            AnimatedBuilder(animation:_logo, builder:(_,__){
              final float = sin(_logo.value * 2 * pi) * 10;
              return Transform.translate(offset:Offset(0,float), child:
                Container(width:110, height:110,
                  decoration:BoxDecoration(
                    borderRadius:BorderRadius.circular(24),
                    boxShadow:[
                      BoxShadow(color:kCyan.withOpacity(.55), blurRadius:24, spreadRadius:2),
                      BoxShadow(color:kRed.withOpacity(.35),  blurRadius:40, spreadRadius:4),
                    ],
                  ),
                  child: ClipRRect(borderRadius:BorderRadius.circular(24),
                    child:Container(color:kCard, child:const Center(child:Text('🐱',style:TextStyle(fontSize:62))))),
                ),
              );
            }),
            const SizedBox(height:14),
            // ── Title
            ShaderMask(
              shaderCallback:(b)=>const LinearGradient(colors:[kCyan,Color(0xFFB0E0FF),kRed]).createShader(b),
              child: const Text('GatoViralMx', style:TextStyle(fontSize:28, fontWeight:FontWeight.w900, color:Colors.white, letterSpacing:-0.5)),
            ),
            const SizedBox(height:4),
            const Text('Elige tu modo de juego', style:TextStyle(color:kMuted, fontSize:13, letterSpacing:.5)),
            const SizedBox(height:28),
            // ── Mode buttons
            _ModeBtn(icon:'⊞', label:'Modo Clásico',   color:kCyan,   onTap:()=>_go(GameMode.classic)),
            const SizedBox(height:12),
            _ModeBtn(icon:'⊕', label:'Piezas Móviles', color:kOrange, onTap:()=>_go(GameMode.wild)),
            const SizedBox(height:12),
            _ModeBtn(icon:'⚡', label:'Super Gato 9×9', color:kRed,    onTap:()=>_go(GameMode.superMode)),
            const SizedBox(height:12),
            _ModeBtn(icon:'🎲', label:'Gato Random',    color:kPurple, onTap:()=>_go(GameMode.random)),
            const SizedBox(height:40),
            // ── VS Preview
            Row(mainAxisAlignment:MainAxisAlignment.center, children:[
              Column(children:[
                Text('X', style:TextStyle(fontSize:38, fontWeight:FontWeight.w900, color:kCyan,
                    shadows:[Shadow(color:kCyan.withOpacity(.7), blurRadius:20)])),
                const Text('Azul Neón', style:TextStyle(color:kMuted, fontSize:11, letterSpacing:1)),
              ]),
              const Padding(padding:EdgeInsets.symmetric(horizontal:20),
                child:Text('VS', style:TextStyle(color:kMuted, fontSize:14, fontWeight:FontWeight.w700, letterSpacing:2))),
              Column(children:[
                Text('O', style:TextStyle(fontSize:38, fontWeight:FontWeight.w900, color:kRed,
                    shadows:[Shadow(color:kRed.withOpacity(.7), blurRadius:20)])),
                const Text('Rojo Neón', style:TextStyle(color:kMuted, fontSize:11, letterSpacing:1)),
              ]),
            ]),
            const SizedBox(height:20),
          ]),
        ),
      ))),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String icon, label; final Color color; final VoidCallback onTap;
  const _ModeBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width:double.infinity,
      padding:const EdgeInsets.symmetric(horizontal:24, vertical:18),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(16),
        border:Border.all(color:color, width:1.5),
        boxShadow:[BoxShadow(color:color.withOpacity(.15), blurRadius:12)],
      ),
      child:Row(children:[
        Text(icon, style:const TextStyle(fontSize:22)),
        const SizedBox(width:12),
        Text(label, style:TextStyle(color:color, fontSize:16, fontWeight:FontWeight.w700)),
      ]),
    ),
  );
}

// ══════════════════════════════════════════
//  SETUP SCREEN
// ══════════════════════════════════════════
class SetupScreen extends StatefulWidget {
  final GameMode mode;
  const SetupScreen({super.key, required this.mode});
  @override State<SetupScreen> createState() => _SetupScreenState();
}
class _SetupScreenState extends State<SetupScreen> {
  Difficulty _diff = Difficulty.medium;

  String get _label => switch(widget.mode){
    GameMode.classic   => 'Modo Clásico',
    GameMode.wild      => 'Piezas Móviles',
    GameMode.superMode => 'Super Gato 9×9',
    GameMode.random    => 'Gato Random',
  };
  Color get _color => switch(widget.mode){
    GameMode.classic   => kCyan,
    GameMode.wild      => kOrange,
    GameMode.superMode => kRed,
    GameMode.random    => kPurple,
  };

  void _start(Opponent opp) => Navigator.pushReplacement(context,
      _slide(GameScreen(mode:widget.mode, opponent:opp, difficulty:_diff)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor:kBg,
    body:SafeArea(child:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:480),
      child:Padding(
        padding:const EdgeInsets.symmetric(horizontal:20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          // Top
          Padding(padding:const EdgeInsets.only(top:16),
            child:Row(children:[
              _BackBtn(onTap:()=>Navigator.pop(context)),
              Expanded(child:Center(child:Text(_label,
                  style:TextStyle(color:_color, fontSize:18, fontWeight:FontWeight.w800)))),
              const SizedBox(width:52),
            ])),
          const SizedBox(height:32),
          // PvP
          _OutlineBtn(label:'👥  2 Jugadores (Local)', color:kCyan, onTap:()=>_start(Opponent.pvp)),
          const SizedBox(height:14),
          // Bot box
          Container(
            padding:const EdgeInsets.all(18),
            decoration:BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(16)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              const Text('🤖 vs Bot — Elige dificultad:',
                  style:TextStyle(color:kMuted, fontSize:13, fontWeight:FontWeight.w600)),
              const SizedBox(height:14),
              Row(children:[
                _DiffPill('Fácil',   Difficulty.easy,   kGreen,  _diff, (d)=>setState(()=>_diff=d)),
                const SizedBox(width:10),
                _DiffPill('Medio',   Difficulty.medium, kOrange, _diff, (d)=>setState(()=>_diff=d)),
                const SizedBox(width:10),
                _DiffPill('Difícil', Difficulty.hard,   kRed,    _diff, (d)=>setState(()=>_diff=d)),
              ]),
              const SizedBox(height:14),
              _OutlineBtn(label:'Jugar vs Bot', color:kRed, onTap:()=>_start(Opponent.bot)),
            ]),
          ),
        ]),
      ),
    ))),
  );
}

class _DiffPill extends StatelessWidget {
  final String label; final Difficulty diff, sel; final Color ac; final Function(Difficulty) onTap;
  const _DiffPill(this.label, this.diff, this.ac, this.sel, this.onTap);
  @override
  Widget build(BuildContext c) {
    final on = diff==sel;
    return Expanded(child:GestureDetector(onTap:()=>onTap(diff),
      child:Container(
        padding:const EdgeInsets.symmetric(vertical:10),
        decoration:BoxDecoration(
          color: on ? ac.withOpacity(.1) : const Color(0x0DFFFFFF),
          borderRadius:BorderRadius.circular(10),
          border:Border.all(color: on ? ac : Colors.white.withOpacity(.15), width:1.5),
        ),
        child:Center(child:Text(label,
            style:TextStyle(color: on ? ac : Colors.white.withOpacity(.5),
                fontSize:14, fontWeight:FontWeight.w700))),
      ),
    ));
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap:onTap,
    child:Container(
      width:double.infinity,
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(14),
        border:Border.all(color:color, width:1.5),
      ),
      child:Center(child:Text(label,
          style:TextStyle(color:color, fontSize:15, fontWeight:FontWeight.w700))),
    ),
  );
}

// ══════════════════════════════════════════
//  GAME STATE
// ══════════════════════════════════════════
class GS {
  GameMode   mode;
  Opponent   opponent;
  Difficulty difficulty;
  String     turn = 'X';
  bool       over = false;
  List<String?> board = List.filled(9,null);
  List<List<String?>> sup = List.generate(9,(_)=>List.filled(9,null));
  List<String?> macroW = List.filled(9,null);
  int  activeMacro = -1;
  int  pX=0, pO=0;
  int? sel;
  // Random
  Ability? curAbility;
  String?  phase;
  int?     tpFrom;
  int      dblLeft = 0;
  String?  cursed, shielded;
  Map<String,bool> nextAbility = {'X':false,'O':false};
  // Score
  Map<String,int> score = {'X':0,'O':0,'draw':0};
  List<int>? winCells;

  GS({required this.mode, required this.opponent, required this.difficulty});

  void reset(){
    final s = Map<String,int>.from(score);
    turn='X'; over=false;
    board=List.filled(9,null);
    sup=List.generate(9,(_)=>List.filled(9,null));
    macroW=List.filled(9,null); activeMacro=-1;
    pX=0; pO=0; sel=null;
    curAbility=null; phase=null; tpFrom=null; dblLeft=0;
    cursed=null; shielded=null;
    nextAbility={'X':false,'O':false};
    winCells=null;
    score=s;
  }
}

// ══════════════════════════════════════════
//  GAME SCREEN
// ══════════════════════════════════════════
class GameScreen extends StatefulWidget {
  final GameMode mode; final Opponent opponent; final Difficulty difficulty;
  const GameScreen({super.key, required this.mode, required this.opponent, required this.difficulty});
  @override State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GS gs;
  final _rng = Random();
  bool _showAbility = false;
  bool _showCurse   = false;

  @override void initState() {
    super.initState();
    gs = GS(mode:widget.mode, opponent:widget.opponent, difficulty:widget.difficulty);
    if (widget.mode==GameMode.random) {
      WidgetsBinding.instance.addPostFrameCallback((_)=>_startRandom());
    }
  }

  bool get _botTurn => widget.opponent==Opponent.bot && gs.turn=='O';

  // ────────────────────────────────────────
  //  WIN / DRAW
  // ────────────────────────────────────────
  String? _win(List<String?> b){
    for(final c in kWinCombos){
      if(b[c[0]]!=null && b[c[0]]==b[c[1]] && b[c[0]]==b[c[2]]) return b[c[0]];
    }
    return null;
  }
  bool _draw(List<String?> b) => b.every((v)=>v!=null);

  void _endGame(String? winner){
    setState((){
      gs.over=true; gs.phase=null;
      if(winner!=null){
        gs.score[winner]=(gs.score[winner]??0)+1;
        for(final c in kWinCombos){
          if(gs.board[c[0]]!=null && gs.board[c[0]]==gs.board[c[1]] && gs.board[c[0]]==gs.board[c[2]]){
            gs.winCells=c; break;
          }
        }
      } else { gs.score['draw']=(gs.score['draw']??0)+1; }
    });
  }

  void _restart(){
    setState(() => gs.reset());
    if(widget.mode==GameMode.random) Future.delayed(const Duration(milliseconds:400),_startRandom);
  }

  // ────────────────────────────────────────
  //  CLASSIC / WILD
  // ────────────────────────────────────────
  void _tap(int i){
    if(widget.mode==GameMode.random){ _tapRandom(i); return; }
    if(gs.over || _botTurn) return;
    if(widget.mode==GameMode.classic){
      if(gs.board[i]!=null) return;
      _move(i);
    } else {
      final pieces = gs.turn=='X' ? gs.pX : gs.pO;
      if(pieces>=3){
        if(gs.board[i]==gs.turn){ setState(()=>gs.sel=i); }
        else if(gs.sel!=null && gs.board[i]==null){
          setState((){gs.board[gs.sel!]=null; gs.sel=null;});
          _move(i, mv:true);
        }
      } else {
        if(gs.board[i]!=null) return;
        _move(i);
      }
    }
  }

  void _move(int i, {bool mv=false}){
    setState((){
      gs.board[i]=gs.turn;
      if(!mv){ if(gs.turn=='X') gs.pX++; else gs.pO++; }
    });
    final w=_win(gs.board);
    if(w!=null){ _endGame(w); return; }
    if(_draw(gs.board) && widget.mode==GameMode.classic){ _endGame(null); return; }
    setState(()=>gs.turn=gs.turn=='X'?'O':'X');
    if(_botTurn) Future.delayed(const Duration(milliseconds:500),_bot);
  }

  // ────────────────────────────────────────
  //  SUPER
  // ────────────────────────────────────────
  void _tapSuper(int ma, int mi){
    if(gs.over||_botTurn) return;
    if(gs.macroW[ma]!=null) return;
    if(gs.sup[ma][mi]!=null) return;
    if(gs.activeMacro!=-1 && gs.activeMacro!=ma) return;
    _superMove(ma,mi);
  }

  void _superMove(int ma, int mi){
    setState((){
      gs.sup[ma][mi]=gs.turn;
      final sw=_win(gs.sup[ma]);
      if(sw!=null) gs.macroW[ma]=sw;
      else if(_draw(gs.sup[ma])) gs.macroW[ma]='Draw';
    });
    final tw=_win(gs.macroW);
    if(tw!=null && tw!='Draw'){ _endGame(tw); return; }
    setState((){
      gs.activeMacro = gs.macroW[mi]!=null ? -1 : mi;
      gs.turn = gs.turn=='X'?'O':'X';
    });
    if(_botTurn) Future.delayed(const Duration(milliseconds:600),_bot);
  }

  // ────────────────────────────────────────
  //  BOT
  // ────────────────────────────────────────
  void _bot(){
    if(gs.over) return;
    final err = gs.difficulty==Difficulty.easy ? .6 : gs.difficulty==Difficulty.medium ? .2 : .0;
    final bad = _rng.nextDouble()<err;
    if(widget.mode==GameMode.classic){
      _move(bad?_rndEmpty(gs.board):_bestClassic());
    } else if(widget.mode==GameMode.wild){
      if(gs.pO<3){ _move(bad?_rndEmpty(gs.board):_bestClassic()); }
      else {
        final mv = bad?_rndWild():_bestWild();
        setState(()=>gs.board[mv['f']!]=null);
        _move(mv['t']!, mv:true);
      }
    } else if(widget.mode==GameMode.superMode){
      final mv = bad?_rndSuper():_bestSuper();
      if(mv!=null) _superMove(mv['ma']!, mv['mi']!);
    }
  }

  int _rndEmpty(List<String?> b){
    final e=[for(int i=0;i<9;i++) if(b[i]==null) i];
    return e[_rng.nextInt(e.length)];
  }

  int _bestClassic(){
    final b=gs.board;
    for(int i=0;i<9;i++){ if(b[i]==null){ b[i]='O'; if(_win(b)=='O'){b[i]=null;return i;} b[i]=null; }}
    for(int i=0;i<9;i++){ if(b[i]==null){ b[i]='X'; if(_win(b)=='X'){b[i]=null;return i;} b[i]=null; }}
    if(b[4]==null) return 4;
    return _rndEmpty(b);
  }

  Map<String,int> _rndWild(){
    final own=[for(int i=0;i<9;i++) if(gs.board[i]=='O') i];
    final emp=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
    return {'f':own[_rng.nextInt(own.length)],'t':emp[_rng.nextInt(emp.length)]};
  }
  Map<String,int> _bestWild(){
    final own=[for(int i=0;i<9;i++) if(gs.board[i]=='O') i];
    final emp=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
    for(final f in own) for(final t in emp){
      gs.board[f]=null; gs.board[t]='O';
      if(_win(gs.board)=='O'){ gs.board[f]='O'; gs.board[t]=null; return{'f':f,'t':t}; }
      gs.board[f]='O'; gs.board[t]=null;
    }
    return _rndWild();
  }

  List<Map<String,int>> _validSuper(){
    List<Map<String,int>> mv=[];
    for(int m=0;m<9;m++){
      if(gs.macroW[m]!=null) continue;
      if(gs.activeMacro!=-1 && gs.activeMacro!=m) continue;
      for(int i=0;i<9;i++) if(gs.sup[m][i]==null) mv.add({'ma':m,'mi':i});
    }
    return mv;
  }
  Map<String,int>? _rndSuper(){ final v=_validSuper(); return v.isEmpty?null:v[_rng.nextInt(v.length)]; }
  Map<String,int>? _bestSuper(){
    final v=_validSuper(); if(v.isEmpty) return null;
    for(final mv in v){ gs.sup[mv['ma']!][mv['mi']!]='O'; if(_win(gs.sup[mv['ma']!])=='O'){gs.sup[mv['ma']!][mv['mi']!]=null;return mv;} gs.sup[mv['ma']!][mv['mi']!]=null; }
    for(final mv in v){ gs.sup[mv['ma']!][mv['mi']!]='X'; if(_win(gs.sup[mv['ma']!])=='X'){gs.sup[mv['ma']!][mv['mi']!]=null;return mv;} gs.sup[mv['ma']!][mv['mi']!]=null; }
    return _rndSuper();
  }

  // ────────────────────────────────────────
  //  RANDOM MODE
  // ────────────────────────────────────────
  void _startRandom(){
    if(gs.over||!mounted) return;
    if(gs.cursed==gs.turn){
      setState(()=>gs.cursed=null);
      _showCurseScreen(); return;
    }
    final p=gs.turn;
    final isAb=gs.nextAbility[p]??false;
    setState(()=>gs.nextAbility[p]=!isAb);
    if(!isAb){ _normalTurn(); }
    else {
      final ab=kAbilities[_rng.nextInt(kAbilities.length)];
      setState((){gs.curAbility=ab; _showAbility=true;});
      if(_botTurn) Future.delayed(const Duration(milliseconds:1800),()=>_botAbility(ab));
    }
  }

  void _normalTurn(){
    setState(()=>gs.phase='normal_place');
    if(_botTurn){
      Future.delayed(const Duration(milliseconds:700),(){
        if(gs.over||!mounted) return;
        setState(()=>gs.phase=null);
        final e=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
        if(e.isEmpty){ _switchTurns(); return; }
        final m=_bestForBot();
        setState(()=>gs.board[m]='O');
        final w=_win(gs.board); if(w!=null){_endGame(w);return;}
        if(_draw(gs.board)){_endGame(null);return;}
        _switchTurns();
      });
    }
  }

  int _bestForBot(){
    final e=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
    if(e.isEmpty) return 0;
    for(int i in e){ gs.board[i]='O'; if(_win(gs.board)=='O'){gs.board[i]=null;return i;} gs.board[i]=null; }
    for(int i in e){ gs.board[i]='X'; if(_win(gs.board)=='X'){gs.board[i]=null;return i;} gs.board[i]=null; }
    if(gs.board[4]==null) return 4;
    return e[_rng.nextInt(e.length)];
  }

  void _showCurseScreen(){
    setState(()=>_showCurse=true);
    Future.delayed(const Duration(milliseconds:2200),(){
      if(!mounted) return;
      setState(()=>_showCurse=false);
      _switchTurns();
    });
  }

  void _useAbility(){
    if(_botTurn||gs.curAbility==null) return;
    setState(()=>_showAbility=false);
    final ab=gs.curAbility!;
    if(ab.auto){
      _execAuto(ab.id);
      if(gs.phase=='double') return; // human handles via clicks
    } else {
      final p=gs.turn, op=p=='X'?'O':'X';
      final own=gs.board.where((v)=>v==p).length;
      final opp=gs.board.where((v)=>v==op).length;
      final emp=gs.board.where((v)=>v==null).length;
      bool can=true;
      if(ab.phase=='steal' && opp==0) can=false;
      if(ab.phase=='teleport_from' && (own==0||emp==0)) can=false;
      if(ab.phase=='erase' && own+opp==0) can=false;
      if(!can){ _switchTurns(); return; }
      setState(()=>gs.phase=ab.phase);
    }
  }

  void _execAuto(String id){
    final p=gs.turn, op=p=='X'?'O':'X';
    final sh=gs.shielded==op;
    setState((){
      switch(id){
        case 'xline':
          for(int pos in [0,2,4,6,8]){
            if(gs.board[pos]==op && sh) continue;
            gs.board[pos]=p;
          }
          if(sh) gs.shielded=null;
        case 'maldicion':
          if(sh){gs.shielded=null;break;}
          gs.cursed=op;
        case 'bomba':
          List<int> pool=[];
          for(int i=0;i<9;i++) if(gs.board[i]!=null){ if(gs.board[i]==op && sh) continue; pool.add(i); }
          int cnt=pool.length<4?pool.length:4;
          for(int j=0;j<cnt;j++){ final ri=_rng.nextInt(pool.length); gs.board[pool[ri]]=null; pool.removeAt(ri); }
          if(sh && cnt>0) gs.shielded=null;
        case 'caos_total':
          List<int> pos=[]; List<String> pcs=[];
          for(int i=0;i<9;i++) if(gs.board[i]!=null){ if(gs.board[i]==op && sh) continue; pos.add(i); pcs.add(gs.board[i]!); }
          for(int i=pcs.length-1;i>0;i--){ final j=_rng.nextInt(i+1); final t=pcs[i];pcs[i]=pcs[j];pcs[j]=t; }
          for(int k=0;k<pos.length;k++) gs.board[pos[k]]=pcs[k];
          if(sh) gs.shielded=null;
        case 'rayo':
          if(sh){gs.shielded=null;break;}
          List<int> oc=[for(int i=0;i<9;i++) if(gs.board[i]==op) i];
          int cnt=oc.length<2?oc.length:2;
          for(int j=0;j<cnt;j++){ final ri=_rng.nextInt(oc.length); gs.board[oc[ri]]=null; oc.removeAt(ri); }
        case 'doble_turno':
          gs.dblLeft=2; gs.phase='double';
          return; // stay in state
        case 'escudo':
          gs.shielded=p;
        case 'invasion':
          List<int> e=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
          int cnt=e.length<2?e.length:2;
          for(int j=0;j<cnt;j++){ final ri=_rng.nextInt(e.length); gs.board[e[ri]]=p; e.removeAt(ri); }
        case 'congelar':
          if(sh) gs.shielded=null;
          gs.cursed=op;
        case 'inversion':
          for(int i=0;i<9;i++){ if(gs.board[i]=='X') gs.board[i]='O'; else if(gs.board[i]=='O') gs.board[i]='X'; }
        case 'duplicar':
          List<int> own=[for(int i=0;i<9;i++) if(gs.board[i]==p) i];
          if(own.isNotEmpty){
            const adj={0:[1,3,4],1:[0,2,3,4,5],2:[1,4,5],3:[0,1,4,6,7],4:[0,1,2,3,5,6,7,8],5:[1,2,4,7,8],6:[3,4,7],7:[3,4,5,6,8],8:[4,5,7]};
            List<int> cands=[];
            for(final pc in own) for(final a in (adj[pc]??[])) if(gs.board[a]==null && !cands.contains(a)) cands.add(a);
            if(cands.isNotEmpty){ final pick=cands[_rng.nextInt(cands.length)]; gs.board[pick]=p; }
          }
      }
    });
    Future.delayed(const Duration(milliseconds:300),_afterAuto);
  }

  void _afterAuto(){
    final w=_win(gs.board); if(w!=null){_endGame(w);return;}
    if(_draw(gs.board)){_endGame(null);return;}
    _switchTurns();
  }

  void _tapRandom(int i){
    if(gs.over||_botTurn) return;
    final ph=gs.phase; if(ph==null) return;
    final p=gs.turn, op=p=='X'?'O':'X';

    switch(ph){
      case 'normal_place':
        if(gs.board[i]!=null) return;
        setState((){gs.board[i]=p; gs.phase=null;});
        final w=_win(gs.board); if(w!=null){_endGame(w);return;}
        if(_draw(gs.board)){_endGame(null);return;}
        _switchTurns();
      case 'steal':
        if(gs.board[i]!=op) return;
        if(gs.shielded==op){setState(()=>gs.shielded=null);_finishInter();return;}
        setState(()=>gs.board[i]=p);
        _finishInter();
      case 'teleport_from':
        if(gs.board[i]!=p) return;
        if(!gs.board.any((v)=>v==null)){_finishInter();return;}
        setState((){gs.tpFrom=i; gs.phase='teleport_to';});
      case 'teleport_to':
        if(gs.board[i]!=null||gs.tpFrom==null) return;
        setState((){gs.board[gs.tpFrom!]=null; gs.board[i]=p; gs.tpFrom=null;});
        _finishInter();
      case 'erase':
        if(gs.board[i]==null) return;
        if(gs.board[i]==op && gs.shielded==op){setState(()=>gs.shielded=null);_finishInter();return;}
        setState(()=>gs.board[i]=null);
        _finishInter();
      case 'double':
        if(gs.board[i]!=null) return;
        setState((){gs.board[i]=p; gs.dblLeft--;});
        final w=_win(gs.board); if(w!=null){setState((){gs.phase=null;gs.dblLeft=0;});_endGame(w);return;}
        if(_draw(gs.board)){setState((){gs.phase=null;gs.dblLeft=0;});_endGame(null);return;}
        if(gs.dblLeft>0){
          if(!gs.board.any((v)=>v==null)){setState((){gs.phase=null;gs.dblLeft=0;});_switchTurns();}
        } else { setState((){gs.phase=null;gs.dblLeft=0;});_switchTurns(); }
    }
  }

  void _selectLine(int li){
    final idx=List<int>.from(kLineDefs[li]['i'] as List);
    final op=gs.turn=='X'?'O':'X';
    final sh=gs.shielded==op;
    setState((){
      for(int i in idx){ if(gs.board[i]==op && sh) continue; gs.board[i]=gs.turn; }
      if(sh) gs.shielded=null;
      gs.phase=null;
    });
    _finishInter();
  }

  void _finishInter(){
    setState(()=>gs.phase=null);
    final w=_win(gs.board); if(w!=null){_endGame(w);return;}
    if(_draw(gs.board)){_endGame(null);return;}
    _switchTurns();
  }

  void _switchTurns(){
    if(gs.over||!mounted) return;
    setState((){gs.curAbility=null; gs.turn=gs.turn=='X'?'O':'X';});
    Future.delayed(const Duration(milliseconds:200),_startRandom);
  }

  // ── Bot random ability
  void _botAbility(Ability ab){
    if(gs.over||!mounted) return;
    setState(()=>_showAbility=false);
    if(ab.auto){
      _execAuto(ab.id);
      if(gs.phase=='double') _botDouble();
    } else {
      switch(ab.phase){
        case 'line_select':
          final li=_bestLine();
          final idx=List<int>.from(kLineDefs[li]['i'] as List);
          final sh=gs.shielded=='X';
          setState((){
            for(int i in idx){ if(gs.board[i]=='X' && sh) continue; gs.board[i]='O'; }
            if(sh) gs.shielded=null; gs.phase=null;
          });
          _finishInter();
        case 'steal':
          if(gs.shielded=='X'){setState(()=>gs.shielded=null);_finishInter();return;}
          final t=_bestSteal();
          if(t!=null) setState(()=>gs.board[t]='O');
          _finishInter();
        case 'teleport_from':
          final own=[for(int i=0;i<9;i++) if(gs.board[i]=='O') i];
          final emp=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
          if(own.isNotEmpty && emp.isNotEmpty){
            int? bf,bt;
            outer: for(final f in own) for(final t in emp){
              gs.board[f]=null; gs.board[t]='O';
              final w=_win(gs.board); gs.board[f]='O'; gs.board[t]=null;
              if(w=='O'){bf=f;bt=t;break outer;}
            }
            final f=bf??own[_rng.nextInt(own.length)];
            final t=bt??emp[_rng.nextInt(emp.length)];
            setState((){gs.board[f]=null; gs.board[t]='O';});
          }
          _finishInter();
        case 'erase':
          if(gs.shielded=='X'){setState(()=>gs.shielded=null);_finishInter();return;}
          final xc=[for(int i=0;i<9;i++) if(gs.board[i]=='X') i];
          if(xc.isNotEmpty) setState(()=>gs.board[xc[_rng.nextInt(xc.length)]]=null);
          _finishInter();
        default: _finishInter();
      }
    }
  }

  void _botDouble(){
    Future.delayed(const Duration(milliseconds:400),(){
      if(gs.over||!mounted) return;
      for(int k=0;k<2;k++){
        final e=[for(int i=0;i<9;i++) if(gs.board[i]==null) i];
        if(e.isEmpty) break;
        final m=_bestForBot();
        setState(()=>gs.board[m]='O');
        final w=_win(gs.board);
        if(w!=null){setState((){gs.phase=null;gs.dblLeft=0;});_endGame(w);return;}
        if(_draw(gs.board)){setState((){gs.phase=null;gs.dblLeft=0;});_endGame(null);return;}
      }
      setState((){gs.phase=null;gs.dblLeft=0;});
      _switchTurns();
    });
  }

  int _bestLine(){
    for(int l=0;l<kLineDefs.length;l++){
      final idx=List<int>.from(kLineDefs[l]['i'] as List);
      final sim=List<String?>.from(gs.board);
      for(final i in idx) sim[i]='O';
      if(_win(sim)=='O') return l;
    }
    for(int l=0;l<kLineDefs.length;l++){
      final idx=List<int>.from(kLineDefs[l]['i'] as List);
      if(idx.where((i)=>gs.board[i]=='X').length>=2) return l;
    }
    return 0;
  }

  int? _bestSteal(){
    final xc=[for(int i=0;i<9;i++) if(gs.board[i]=='X') i];
    if(xc.isEmpty) return null;
    for(final c in xc){ final sim=List<String?>.from(gs.board); sim[c]='O'; if(_win(sim)=='O') return c; }
    return xc[_rng.nextInt(xc.length)];
  }

  // ────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────
  String get _modeLabel => switch(widget.mode){
    GameMode.classic   => 'Clásico',
    GameMode.wild      => 'Piezas Móviles',
    GameMode.superMode => 'Super Gato',
    GameMode.random    => 'Gato Random',
  };

  String get _instruction {
    if(gs.over) return '';
    switch(gs.phase){
      case 'normal_place': return '${gs.turn=='X'?'🔵':'🔴'} Coloca una ficha';
      case 'steal':        return '🎭 Roba una ficha del rival';
      case 'teleport_from':return '🔮 Elige tu ficha a mover';
      case 'teleport_to':  return '🔮 Elige el destino';
      case 'erase':        return '🧹 Elige una ficha a borrar';
      case 'line_select':  return '📏 Elige una línea';
      case 'double':       return '🎯 Coloca ficha (${gs.dblLeft} restante${gs.dblLeft>1?"s":""})';
      default:             return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children:[
        SafeArea(child:Center(child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:480),
          child:SingleChildScrollView(
            padding:const EdgeInsets.symmetric(horizontal:20),
            child:Column(children:[
              // ── Top bar
              Padding(padding:const EdgeInsets.only(top:14),
                child:Row(children:[
                  _BackBtn(onTap:()=>Navigator.pushReplacement(context,_slide(const MenuScreen()))),
                  Expanded(child:Center(child:Text(_modeLabel,
                      style:const TextStyle(color:kText,fontSize:16,fontWeight:FontWeight.w700)))),
                  _IconBtn(icon:'↺', onTap:_restart),
                ])),
              const SizedBox(height:14),
              // ── Score
              Row(mainAxisAlignment:MainAxisAlignment.center, children:[
                _ScoreCol('J1',    gs.score['X']??0,    kCyan),
                const SizedBox(width:28),
                _ScoreCol('EMPATE',gs.score['draw']??0, Colors.white.withOpacity(.45)),
                const SizedBox(width:28),
                _ScoreCol('J2',    gs.score['O']??0,    kRed),
              ]),
              const SizedBox(height:10),
              // ── Turn
              if(!gs.over) _TurnRow(turn:gs.turn, shielded:gs.shielded==gs.turn),
              const SizedBox(height:6),
              // ── Instruction
              if(_instruction.isNotEmpty)
                Container(
                  width:double.infinity,
                  padding:const EdgeInsets.symmetric(vertical:10,horizontal:14),
                  margin:const EdgeInsets.only(bottom:8),
                  decoration:BoxDecoration(
                    color:Colors.white.withOpacity(.06),
                    borderRadius:BorderRadius.circular(10),
                    border:Border.all(color:Colors.white.withOpacity(.12)),
                  ),
                  child:Text(_instruction,textAlign:TextAlign.center,
                      style:const TextStyle(color:kText,fontSize:14,fontWeight:FontWeight.w600)),
                ),
              // ── Game Over
              if(gs.over) _GameOverCard(winner:_win(gs.board), onReplay:_restart),
              const SizedBox(height:8),
              // ── Board
              if(widget.mode==GameMode.superMode) _SuperBoard(gs:gs, onTap:_tapSuper)
              else _MainBoard(gs:gs, mode:widget.mode, botTurn:_botTurn, onTap:_tap),
              const SizedBox(height:12),
              // ── Line selector
              if(widget.mode==GameMode.random && gs.phase=='line_select')
                _LineSelector(onSelect:_selectLine),
              const SizedBox(height:24),
            ]),
          ),
        ))),
        // ── Overlays
        if(_showAbility && gs.curAbility!=null)
          _AbilityOverlay(ab:gs.curAbility!, player:gs.turn, isBot:_botTurn, onUse:_useAbility),
        if(_showCurse)
          _CurseOverlay(player:gs.turn),
      ]),
    );
  }
}

// ══════════════════════════════════════════
//  BOARD WIDGETS
// ══════════════════════════════════════════
class _MainBoard extends StatelessWidget {
  final GS gs; final GameMode mode; final bool botTurn;
  final Function(int) onTap;
  const _MainBoard({required this.gs, required this.mode, required this.botTurn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder:(ctx,cns){
      final sz = (cns.maxWidth - 20) / 3;
      return Wrap(
        spacing:10, runSpacing:10,
        children:[for(int i=0;i<9;i++) _Cell(i:i, gs:gs, mode:mode, botTurn:botTurn, sz:sz, onTap:onTap)],
      );
    });
  }
}

class _Cell extends StatelessWidget {
  final int i; final GS gs; final GameMode mode; final bool botTurn;
  final double sz; final Function(int) onTap;
  const _Cell({required this.i, required this.gs, required this.mode, required this.botTurn, required this.sz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final val=gs.board[i];
    final isWin=gs.winCells?.contains(i)??false;
    final isSel=mode==GameMode.wild && gs.sel==i;
    final ph=gs.phase;
    final p=gs.turn, op=p=='X'?'O':'X';

    Color border=Colors.white.withOpacity(.05);
    Color bg=kCell;

    if(isSel){ border=Colors.white.withOpacity(.6); bg=Colors.white.withOpacity(.08); }
    if(isWin){ final c=val=='X'?kCyan:kRed; border=c; bg=c.withOpacity(.15); }

    if(mode==GameMode.random && !botTurn){
      if(ph=='steal'         && val==op)                   { border=kRed;    bg=kRed.withOpacity(.12); }
      if(ph=='teleport_from' && val==p)                    { border=kCyan;   bg=kCyan.withOpacity(.1); }
      if(ph=='teleport_to'   && val==null)                 { border=Colors.white.withOpacity(.3); }
      if(ph=='teleport_from' && i==gs.tpFrom)              { border=const Color(0xFF3498DB); bg=const Color(0xFF3498DB).withOpacity(.2); }
      if(ph=='erase'         && val!=null)                 { border=kOrange; bg=kOrange.withOpacity(.1); }
      if(ph=='double'        && val==null)                 { border=Colors.white.withOpacity(.3); }
    }

    return GestureDetector(
      onTap:()=>onTap(i),
      child:AnimatedContainer(
        duration:const Duration(milliseconds:150),
        width:sz, height:sz,
        decoration:BoxDecoration(
          color:bg,
          borderRadius:BorderRadius.circular(18),
          border:Border.all(color:border,width:1.5),
          boxShadow:isWin?[BoxShadow(color:(val=='X'?kCyan:kRed).withOpacity(.4),blurRadius:16,spreadRadius:2)]:null,
        ),
        child:Center(child:val!=null?Text(val,style:TextStyle(
          fontSize:sz*.42, fontWeight:FontWeight.w900,
          color:val=='X'?kCyan:kRed,
          shadows:[Shadow(color:(val=='X'?kCyan:kRed).withOpacity(.6),blurRadius:16)],
        )):null),
      ),
    );
  }
}

class _SuperBoard extends StatelessWidget {
  final GS gs; final Function(int,int) onTap;
  const _SuperBoard({required this.gs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap:true, physics:const NeverScrollableScrollPhysics(),
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,mainAxisSpacing:8,crossAxisSpacing:8),
      itemCount:9,
      itemBuilder:(_,ma){
        final winner=gs.macroW[ma];
        final isActive=(gs.activeMacro==-1||gs.activeMacro==ma)&&winner==null&&!gs.over;
        Color mb=Colors.transparent, mbg=Colors.white.withOpacity(.04);
        if(isActive){ mb=Colors.white.withOpacity(.3); mbg=Colors.white.withOpacity(.08); }
        if(winner=='X'){ mb=kCyan; mbg=kCyan.withOpacity(.15); }
        if(winner=='O'){ mb=kRed;  mbg=kRed.withOpacity(.15); }
        return Container(
          decoration:BoxDecoration(color:mbg,borderRadius:BorderRadius.circular(12),border:Border.all(color:mb,width:1.5)),
          padding:const EdgeInsets.all(4),
          child:winner!=null && winner!='Draw'
            ?Center(child:Text(winner,style:TextStyle(fontSize:36,fontWeight:FontWeight.w900,
                color:winner=='X'?kCyan:kRed,shadows:[Shadow(color:(winner=='X'?kCyan:kRed).withOpacity(.6),blurRadius:16)])))
            :GridView.builder(
                physics:const NeverScrollableScrollPhysics(),
                gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,mainAxisSpacing:3,crossAxisSpacing:3),
                itemCount:9,
                itemBuilder:(_,mi){
                  final v=gs.sup[ma][mi];
                  return GestureDetector(onTap:()=>onTap(ma,mi),
                    child:Container(
                      decoration:BoxDecoration(color:kCell,borderRadius:BorderRadius.circular(6)),
                      child:Center(child:v!=null?Text(v,style:TextStyle(
                        fontSize:14,fontWeight:FontWeight.w900,
                        color:v=='X'?kCyan:kRed,
                        shadows:[Shadow(color:(v=='X'?kCyan:kRed).withOpacity(.5),blurRadius:8)],
                      )):null),
                    ),
                  );
                }),
        );
      },
    );
  }
}

class _LineSelector extends StatelessWidget {
  final Function(int) onSelect;
  const _LineSelector({required this.onSelect});
  @override
  Widget build(BuildContext context) => Column(children:[
    const Text('ELIGE UNA LÍNEA:',style:TextStyle(color:kMuted,fontSize:12,fontWeight:FontWeight.w700,letterSpacing:1)),
    const SizedBox(height:8),
    GridView.builder(
      shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,mainAxisSpacing:6,crossAxisSpacing:6,childAspectRatio:2.4),
      itemCount:kLineDefs.length,
      itemBuilder:(_,i)=>GestureDetector(
        onTap:()=>onSelect(i),
        child:Container(
          decoration:BoxDecoration(
            color:kCyan.withOpacity(.07),
            borderRadius:BorderRadius.circular(10),
            border:Border.all(color:kCyan.withOpacity(.35)),
          ),
          child:Center(child:Text(kLineDefs[i]['label'] as String,
              style:const TextStyle(color:kCyan,fontSize:10,fontWeight:FontWeight.w700),textAlign:TextAlign.center)),
        ),
      ),
    ),
  ]);
}

// ══════════════════════════════════════════
//  SMALL WIDGETS
// ══════════════════════════════════════════
class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext c) => GestureDetector(onTap:onTap,
    child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(10),
          border:Border.all(color:Colors.white.withOpacity(.25),width:1.5)),
      child:const Text('← Volver',style:TextStyle(color:kText,fontSize:13,fontWeight:FontWeight.w600))));
}

class _IconBtn extends StatelessWidget {
  final String icon; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext c) => GestureDetector(onTap:onTap,
    child:Container(width:38,height:38,
      decoration:BoxDecoration(color:Colors.white.withOpacity(.06),borderRadius:BorderRadius.circular(10),
          border:Border.all(color:Colors.white.withOpacity(.18),width:1.5)),
      child:Center(child:Text(icon,style:const TextStyle(color:kText,fontSize:18)))));
}

class _ScoreCol extends StatelessWidget {
  final String label; final int value; final Color color;
  const _ScoreCol(this.label,this.value,this.color);
  @override
  Widget build(BuildContext c) => Column(children:[
    Text(label,style:const TextStyle(color:kMuted,fontSize:11,fontWeight:FontWeight.w700,letterSpacing:1.5)),
    const SizedBox(height:2),
    Text('$value',style:TextStyle(color:color,fontSize:36,fontWeight:FontWeight.w900,
        shadows:[Shadow(color:color.withOpacity(.5),blurRadius:16)])),
  ]);
}

class _TurnRow extends StatelessWidget {
  final String turn; final bool shielded;
  const _TurnRow({required this.turn, required this.shielded});
  @override
  Widget build(BuildContext c){
    final col=turn=='X'?kCyan:kRed;
    return Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      const Text('Turno de: ',style:TextStyle(color:kText,fontSize:16,fontWeight:FontWeight.w700)),
      Text(turn,style:TextStyle(color:col,fontSize:16,fontWeight:FontWeight.w700,
          shadows:[Shadow(color:col.withOpacity(.6),blurRadius:12)])),
      if(shielded)...[const SizedBox(width:6),const Text('🛡️',style:TextStyle(fontSize:18))],
    ]);
  }
}

class _GameOverCard extends StatelessWidget {
  final String? winner; final VoidCallback onReplay;
  const _GameOverCard({required this.winner, required this.onReplay});
  @override
  Widget build(BuildContext c){
    final col=winner=='X'?kCyan:winner=='O'?kRed:Colors.white.withOpacity(.7);
    return Column(children:[
      Text(winner!=null?'¡Ganó $winner!':'¡Empate!',style:TextStyle(
        color:col,fontSize:26,fontWeight:FontWeight.w900,
        shadows:winner!=null?[Shadow(color:col.withOpacity(.6),blurRadius:20)]:null,
      )),
      const SizedBox(height:10),
      GestureDetector(onTap:onReplay,
        child:Container(padding:const EdgeInsets.symmetric(horizontal:28,vertical:12),
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),
              border:Border.all(color:kCyan,width:1.5)),
          child:const Text('Jugar de nuevo',style:TextStyle(color:kCyan,fontWeight:FontWeight.w700)))),
      const SizedBox(height:8),
    ]);
  }
}

// ══════════════════════════════════════════
//  ABILITY OVERLAY
// ══════════════════════════════════════════
class _AbilityOverlay extends StatefulWidget {
  final Ability ab; final String player; final bool isBot; final VoidCallback onUse;
  const _AbilityOverlay({required this.ab, required this.player, required this.isBot, required this.onUse});
  @override State<_AbilityOverlay> createState()=>_AbilityOverlayState();
}
class _AbilityOverlayState extends State<_AbilityOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _sc;
  @override void initState(){ super.initState(); _c=AnimationController(vsync:this,duration:const Duration(milliseconds:400)); _sc=CurvedAnimation(parent:_c,curve:Curves.elasticOut); _c.forward(); }
  @override void dispose(){ _c.dispose(); super.dispose(); }

  String get _typeName => switch(widget.ab.id){
    'maldicion'||'congelar' => 'MALDICIÓN',
    'bomba'||'caos_total'||'inversion' => 'CAOS',
    'escudo' => 'DEFENSA',
    'doble_turno'||'duplicar' => 'BONUS',
    'teletransporte'||'borrador' => 'UTILIDAD',
    _ => 'OFENSIVA',
  };

  @override
  Widget build(BuildContext c){
    final ab=widget.ab;
    return Container(
      color:Colors.black.withOpacity(.87),
      child:Center(child:ScaleTransition(scale:_sc,
        child:Container(
          margin:const EdgeInsets.all(20),
          constraints:const BoxConstraints(maxWidth:340),
          padding:const EdgeInsets.fromLTRB(24,30,24,26),
          decoration:BoxDecoration(
            gradient:const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
                colors:[Color(0xFF0D1220),Color(0xFF111827)]),
            borderRadius:BorderRadius.circular(24),
            border:Border.all(color:ab.color,width:1.5),
            boxShadow:[BoxShadow(color:ab.color.withOpacity(.3),blurRadius:30,spreadRadius:2),
              BoxShadow(color:Colors.black.withOpacity(.6),blurRadius:40)],
          ),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            Text('TURNO DE ${widget.player}',style:const TextStyle(color:kMuted,fontSize:12,letterSpacing:2,fontWeight:FontWeight.w600)),
            const SizedBox(height:10),
            Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:3),
              decoration:BoxDecoration(color:ab.color,borderRadius:BorderRadius.circular(20)),
              child:Text(_typeName,style:const TextStyle(color:Color(0xFF07090F),fontSize:11,fontWeight:FontWeight.w900,letterSpacing:2))),
            const SizedBox(height:18),
            Text(ab.icon,style:const TextStyle(fontSize:64)),
            const SizedBox(height:14),
            Text(ab.name,style:TextStyle(color:ab.color,fontSize:26,fontWeight:FontWeight.w900,
                shadows:[Shadow(color:ab.color.withOpacity(.5),blurRadius:20)])),
            const SizedBox(height:10),
            Text(ab.desc,textAlign:TextAlign.center,
                style:const TextStyle(color:Color(0xB3FFFFFF),fontSize:14,height:1.55)),
            const SizedBox(height:22),
            GestureDetector(
              onTap:widget.isBot?null:widget.onUse,
              child:Container(width:double.infinity,padding:const EdgeInsets.all(13),
                decoration:BoxDecoration(
                  borderRadius:BorderRadius.circular(14),
                  border:Border.all(color:ab.color,width:1.5),
                  boxShadow:[BoxShadow(color:ab.color.withOpacity(.3),blurRadius:15)],
                ),
                child:Center(child:Text(
                  widget.isBot?'🤖 Bot ejecutando...':'⚡ ¡USAR!',
                  style:TextStyle(color:widget.isBot?ab.color.withOpacity(.5):ab.color,
                      fontSize:16,fontWeight:FontWeight.w800,letterSpacing:.5),
                )),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}

// ══════════════════════════════════════════
//  CURSE OVERLAY
// ══════════════════════════════════════════
class _CurseOverlay extends StatefulWidget {
  final String player;
  const _CurseOverlay({required this.player});
  @override State<_CurseOverlay> createState()=>_CurseOverlayState();
}
class _CurseOverlayState extends State<_CurseOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _sh;
  @override void initState(){
    super.initState();
    _c=AnimationController(vsync:this,duration:const Duration(milliseconds:500));
    _sh=TweenSequence([
      TweenSequenceItem(tween:Tween(begin:0.0,end:-14.0),weight:20),
      TweenSequenceItem(tween:Tween(begin:-14.0,end:14.0),weight:20),
      TweenSequenceItem(tween:Tween(begin:14.0,end:-9.0),weight:20),
      TweenSequenceItem(tween:Tween(begin:-9.0,end:9.0),weight:20),
      TweenSequenceItem(tween:Tween(begin:9.0,end:0.0),weight:20),
    ]).animate(_c);
    Future.delayed(const Duration(milliseconds:100),()=>_c.forward());
  }
  @override void dispose(){ _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c)=>Container(
    color:const Color(0xE6500064),
    child:Center(child:AnimatedBuilder(animation:_sh,
      builder:(_,child)=>Transform.translate(offset:Offset(_sh.value,0),child:child),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('💀',style:TextStyle(fontSize:80)),
        const SizedBox(height:12),
        Text('¡${widget.player} ESTÁ MALDITO!',style:const TextStyle(
          color:Color(0xFFE879F9),fontSize:32,fontWeight:FontWeight.w900,
          shadows:[Shadow(color:Color(0xFFC026D3),blurRadius:20)])),
        const SizedBox(height:8),
        const Text('Pierdes este turno...',style:TextStyle(color:Color(0xCCFFFFFF),fontSize:18)),
      ]),
    )),
  );
}

// ══════════════════════════════════════════
//  NAV HELPER
// ══════════════════════════════════════════
PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
  pageBuilder:(_,__,___)=>page,
  transitionsBuilder:(_,anim,__,child)=>SlideTransition(
    position:Tween(begin:const Offset(1,0),end:Offset.zero)
        .animate(CurvedAnimation(parent:anim,curve:Curves.easeOutCubic)),
    child:child,
  ),
  transitionDuration:const Duration(milliseconds:300),
);