import 'package:flutter/material.dart';
import 'dart:math';

// --- Data Models ---

enum Side { red, black }

enum PieceType {
  general, // 帅/将 -> Commander
  advisor, // 仕/士 -> Bodyguard
  elephant, // 相/象 -> Heavy Armor/Tank
  horse, // 马 -> Motorcycle
  chariot, // 车 -> Armored Car
  cannon, // 炮 -> Missile/Artillery
  soldier, // 兵/卒 -> Infantry/Robot
}

class ChessPiece {
  final String id;
  final Side side;
  final PieceType type;
  int row;
  int col;

  ChessPiece({
    required this.id,
    required this.side,
    required this.type,
    required this.row,
    required this.col,
  });
}

// --- Main Game Widget ---

class ModernChessGame extends StatefulWidget {
  const ModernChessGame({super.key});

  @override
  State<ModernChessGame> createState() => _ModernChessGameState();
}

class _ModernChessGameState extends State<ModernChessGame> {
  late List<ChessPiece> pieces;
  ChessPiece? selectedPiece;
  Side currentTurn = Side.red;
  bool isVsComputer = false; // New: toggle for computer opponent
  
  // Game board dimensions
  final int rows = 10;
  final int cols = 9;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      pieces = _initPieces();
      currentTurn = Side.red;
      selectedPiece = null;
      isVsComputer = false;
    });
  }

  void _startVsComputer() {
    setState(() {
      isVsComputer = true;
      _resetGame();
      isVsComputer = true; // Keep it true after reset
    });
  }

  void _startTwoPlayer() {
    setState(() {
      isVsComputer = false;
      _resetGame();
      isVsComputer = false;
    });
  }

  List<ChessPiece> _initPieces() {
    List<ChessPiece> newPieces = [];
    int idCounter = 0;

    void addPiece(Side side, PieceType type, int r, int c) {
      newPieces.add(ChessPiece(
        id: '${side}_${type}_${idCounter++}',
        side: side,
        type: type,
        row: r,
        col: c,
      ));
    }

    // Setup Black (Top)
    addPiece(Side.black, PieceType.chariot, 0, 0);
    addPiece(Side.black, PieceType.horse, 0, 1);
    addPiece(Side.black, PieceType.elephant, 0, 2);
    addPiece(Side.black, PieceType.advisor, 0, 3);
    addPiece(Side.black, PieceType.general, 0, 4);
    addPiece(Side.black, PieceType.advisor, 0, 5);
    addPiece(Side.black, PieceType.elephant, 0, 6);
    addPiece(Side.black, PieceType.horse, 0, 7);
    addPiece(Side.black, PieceType.chariot, 0, 8);
    addPiece(Side.black, PieceType.cannon, 2, 1);
    addPiece(Side.black, PieceType.cannon, 2, 7);
    for (int i = 0; i < 5; i++) {
      addPiece(Side.black, PieceType.soldier, 3, i * 2);
    }

    // Setup Red (Bottom)
    addPiece(Side.red, PieceType.chariot, 9, 0);
    addPiece(Side.red, PieceType.horse, 9, 1);
    addPiece(Side.red, PieceType.elephant, 9, 2);
    addPiece(Side.red, PieceType.advisor, 9, 3);
    addPiece(Side.red, PieceType.general, 9, 4);
    addPiece(Side.red, PieceType.advisor, 9, 5);
    addPiece(Side.red, PieceType.elephant, 9, 6);
    addPiece(Side.red, PieceType.horse, 9, 7);
    addPiece(Side.red, PieceType.chariot, 9, 8);
    addPiece(Side.red, PieceType.cannon, 7, 1);
    addPiece(Side.red, PieceType.cannon, 7, 7);
    for (int i = 0; i < 5; i++) {
      addPiece(Side.red, PieceType.soldier, 6, i * 2);
    }

    return newPieces;
  }

  void _handleTap(int row, int col) {
    if (isVsComputer && currentTurn == Side.black) {
      // If vs computer and it's computer's turn, ignore taps
      return;
    }

    // Find if a piece occupies this spot
    final tappedPiece = pieces.firstWhere(
      (p) => p.row == row && p.col == col,
      orElse: () => ChessPiece(id: 'empty', side: Side.red, type: PieceType.soldier, row: -1, col: -1),
    );
    
    bool isPiece = tappedPiece.row != -1;

    if (selectedPiece == null) {
      // Select a piece if it belongs to the current turn
      if (isPiece && tappedPiece.side == currentTurn) {
        setState(() {
          selectedPiece = tappedPiece;
        });
      }
    } else {
      // A piece is already selected
      if (isPiece && tappedPiece.side == currentTurn) {
        // Change selection to another friendly piece
        setState(() {
          selectedPiece = tappedPiece;
        });
      } else {
        // Attempt to move or capture
        // For simplicity, allow any move (no strict rules enforced)
        bool canMove = true; // In full implementation, check rules here
        
        if (canMove) {
          if (isPiece && tappedPiece.side != currentTurn) {
            // Capture
            setState(() {
              pieces.remove(tappedPiece);
              selectedPiece!.row = row;
              selectedPiece!.col = col;
              selectedPiece = null;
              _switchTurn();
            });
          } else if (!isPiece) {
            // Move to empty spot
            setState(() {
              selectedPiece!.row = row;
              selectedPiece!.col = col;
              selectedPiece = null;
              _switchTurn();
            });
          }
        }
      }
    }
  }

  void _switchTurn() {
    currentTurn = currentTurn == Side.red ? Side.black : Side.red;
    if (isVsComputer && currentTurn == Side.black) {
      // Computer's turn - delay then make move
      Future.delayed(const Duration(seconds: 1), () {
        _computerMove();
      });
    }
  }

  void _computerMove() {
    if (!mounted) return;

    // Simple AI: Randomly select a computer piece and move it to a random adjacent or nearby valid position
    final computerPieces = pieces.where((p) => p.side == Side.black).toList();
    if (computerPieces.isEmpty) return;

    // Shuffle and pick a random piece
    computerPieces.shuffle(Random());
    final pieceToMove = computerPieces.first;

    // Generate possible moves: for simplicity, nearby positions (up to 2 steps in any direction)
    List<List<int>> possibleMoves = [];
    for (int dr = -2; dr <= 2; dr++) {
      for (int dc = -2; dc <= 2; dc++) {
        if (dr == 0 && dc == 0) continue; // Not staying put
        int newRow = pieceToMove.row + dr;
        int newCol = pieceToMove.col + dc;
        if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
          // Check if occupied by own piece
          bool occupiedByOwn = pieces.any((p) => p.row == newRow && p.col == newCol && p.side == Side.black);
          if (!occupiedByOwn) {
            possibleMoves.add([newRow, newCol]);
          }
        }
      }
    }

    if (possibleMoves.isEmpty) {
      // If no moves, skip or try another piece (for simplicity, just end turn)
      _switchTurn();
      return;
    }

    // Pick random move
    possibleMoves.shuffle(Random());
    final move = possibleMoves.first;
    final targetRow = move[0];
    final targetCol = move[1];

    // Check if capturing
    final capturedPiece = pieces.firstWhere(
      (p) => p.row == targetRow && p.col == targetCol,
      orElse: () => ChessPiece(id: 'empty', side: Side.red, type: PieceType.soldier, row: -1, col: -1),
    );
    setState(() {
      if (capturedPiece.row != -1) {
        pieces.remove(capturedPiece);
      }
      pieceToMove.row = targetRow;
      pieceToMove.col = targetCol;
      _switchTurn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TACTICAL CHESS // 现代象棋'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selection
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startTwoPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVsComputer ? Colors.grey : Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('双人模式'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _startVsComputer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVsComputer ? Colors.cyan : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('人机对战'),
                ),
              ],
            ),
          ),

          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerIndicator(Side.black, isVsComputer && currentTurn == Side.black ? 'AI思考中...' : ''),
                const Text("VS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                _buildPlayerIndicator(Side.red, ''),
              ],
            ),
          ),
          
          // Game Board
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate grid size to fit screen while maintaining aspect ratio
                  double boardWidth = constraints.maxWidth - 20;
                  double boardHeight = constraints.maxHeight - 20;
                  
                  // Xiangqi board ratio is roughly 9:10
                  double cellSize = boardWidth / 9;
                  if (cellSize * 10 > boardHeight) {
                    cellSize = boardHeight / 10;
                    boardWidth = cellSize * 9;
                  }

                  return Container(
                    width: boardWidth,
                    height: cellSize * 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                      color: const Color(0xFF0A0A0A),
                    ),
                    child: Stack(
                      children: [
                        // 1. The Grid Lines
                        CustomPaint(
                          size: Size(boardWidth, cellSize * 10),
                          painter: BoardPainter(cellSize: cellSize),
                        ),
                        
                        // 2. The Pieces
                        ...pieces.map((p) => Positioned(
                          left: p.col * cellSize,
                          top: p.row * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: GestureDetector(
                            onTap: () => _handleTap(p.row, p.col),
                            child: _buildPieceWidget(p, cellSize),
                          ),
                        )),

                        // 3. Selection Highlight
                        if (selectedPiece != null)
                          Positioned(
                            left: selectedPiece!.col * cellSize,
                            top: selectedPiece!.row * cellSize,
                            width: cellSize,
                            height: cellSize,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.yellowAccent, width: 3),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellowAccent.withOpacity(0.4),
                                      blurRadius: 10,
                                    )
                                  ]
                                ),
                              ),
                            ),
                          ),

                        // 4. Invisible Tappable Grid (for moving to empty spaces)
                        // We create a grid of detectors
                        ...List.generate(90, (index) {
                          int r = index ~/ 9;
                          int c = index % 9;
                          return Positioned(
                            left: c * cellSize,
                            top: r * cellSize,
                            width: cellSize,
                            height: cellSize,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => _handleTap(r, c),
                              child: Container(), // Invisible container
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(Side side, String extraText) {
    bool isActive = currentTurn == side;
    Color color = side == Side.red ? Colors.redAccent : Colors.blueAccent; // Modern Black is Blue/Cyan
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        border: Border.all(color: isActive ? color : Colors.transparent),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: color, size: 12),
              const SizedBox(width: 8),
              Text(
                side == Side.red ? "RED FORCE" : "BLUE SQUAD",
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (extraText.isNotEmpty)
            Text(
              extraText,
              style: const TextStyle(color: Colors.cyan, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildPieceWidget(ChessPiece piece, double size) {
    Color color = piece.side == Side.red ? Colors.redAccent : Colors.blueAccent;
    IconData icon;
    String label;

    switch (piece.type) {
      case PieceType.general:
        icon = Icons.stars; // Commander
        label = "CMD";
        break;
      case PieceType.advisor:
        icon = Icons.security; // Bodyguard
        label = "SEC";
        break;
      case PieceType.elephant:
        icon = Icons.shield; // Heavy Defense
        label = "DEF";
        break;
      case PieceType.horse:
        icon = Icons.motorcycle; // Motorcycle
        label = "MOTO";
        break;
      case PieceType.chariot:
        icon = Icons.directions_car_filled; // Armored Car
        label = "TANK";
        break;
      case PieceType.cannon:
        icon = Icons.rocket_launch; // Missile
        label = "ARTY";
        break;
      case PieceType.soldier:
        icon = Icons.smart_toy; // Robot/Infantry
        label = "BOT";
        break;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: size * 0.4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size * 0.15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Board Painter ---

class BoardPainter extends CustomPainter {
  final double cellSize;

  BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.stroke;

    double width = size.width;
    double height = size.height;
    
    // Adjust offsets to center lines in cells
    double halfCell = cellSize / 2;

    // Draw Horizontal Lines
    for (int i = 0; i < 10; i++) {
      double y = i * cellSize + halfCell;
      canvas.drawLine(Offset(halfCell, y), Offset(width - halfCell, y), paint);
      canvas.drawLine(Offset(halfCell, y), Offset(width - halfCell, y), glowPaint);
    }

    // Draw Vertical Lines
    for (int i = 0; i < 9; i++) {
      double x = i * cellSize + halfCell;
      // Top half
      canvas.drawLine(Offset(x, halfCell), Offset(x, cellSize * 4 + halfCell), paint);
      // Bottom half
      canvas.drawLine(Offset(x, cellSize * 5 + halfCell), Offset(x, height - halfCell), paint);
    }

    // Draw River Borders
    canvas.drawLine(Offset(halfCell, cellSize * 4 + halfCell), Offset(width - halfCell, cellSize * 4 + halfCell), paint);
    canvas.drawLine(Offset(halfCell, cellSize * 5 + halfCell), Offset(width - halfCell, cellSize * 5 + halfCell), paint);

    // Draw Palaces (X shapes)
    // Top Palace
    canvas.drawLine(Offset(3 * cellSize + halfCell, 0 + halfCell), Offset(5 * cellSize + halfCell, 2 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(5 * cellSize + halfCell, 0 + halfCell), Offset(3 * cellSize + halfCell, 2 * cellSize + halfCell), paint);
    
    // Bottom Palace
    canvas.drawLine(Offset(3 * cellSize + halfCell, 7 * cellSize + halfCell), Offset(5 * cellSize + halfCell, 9 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(5 * cellSize + halfCell, 7 * cellSize + halfCell), Offset(3 * cellSize + halfCell, 9 * cellSize + halfCell), paint);

    // Draw "River" Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: "NO MAN'S LAND",
        style: TextStyle(
          color: Colors.cyan.withOpacity(0.2),
          fontSize: cellSize * 0.4,
          fontWeight: FontWeight.bold,
          letterSpacing: 5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((width - textPainter.width) / 2, cellSize * 4.5 + halfCell - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
