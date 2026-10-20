import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Web Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChessBoardPage(),
    );
  }
}

class ChessBoardPage extends StatefulWidget {
  const ChessBoardPage({super.key});

  @override
  State<ChessBoardPage> createState() => _ChessBoardPageState();
}

class _ChessBoardPageState extends State<ChessBoardPage> {
  String currentFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  String statusMessage = 'คลิกเลือกตัวหมาก แล้วคลิกช่องที่ต้องการเดิน';
  bool isLoading = false;

  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    // ปลุก Server ทันทีที่เปิดหน้าเว็บขึ้นมา
    wakeUpServer();
  }

  // ฟังก์ชันยิง HTTP Request เพื่อปลุก Render Backend
  Future<void> wakeUpServer() async {
    try {
      final response = await http.get(
        Uri.parse('https://chessflask-api.onrender.com/'),
      );
      if (response.statusCode == 200) {
        print('Server is awake!');
      }
    } catch (e) {
      print('Error waking up server: $e');
    }
  }

  List<List<String>> parseFenToBoard(String fen) {
    String boardPart = fen.split(' ')[0];
    List<String> ranks = boardPart.split('/');
    List<List<String>> board = [];

    for (String rank in ranks) {
      List<String> row = [];
      for (int i = 0; i < rank.length; i++) {
        String char = rank[i];
        if (int.tryParse(char) != null) {
          int emptyCount = int.parse(char);
          for (int e = 0; e < emptyCount; e++) {
            row.add('');
          }
        } else {
          row.add(char);
        }
      }
      board.add(row);
    }
    return board;
  }

  String generateFenFromBoard(List<List<String>> board) {
    List<String> ranks = [];
    for (int r = 0; r < 8; r++) {
      String rankStr = '';
      int emptyCount = 0;
      for (int c = 0; c < 8; c++) {
        String piece = board[r][c];
        if (piece.isEmpty) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            rankStr += emptyCount.toString();
            emptyCount = 0;
          }
          rankStr += piece;
        }
      }
      if (emptyCount > 0) {
        rankStr += emptyCount.toString();
      }
      ranks.add(rankStr);
    }

    List<String> fenParts = currentFen.split(' ');
    String activeColor = (fenParts.length > 1 && fenParts[1] == 'w')
        ? 'b'
        : 'w';
    String castling = fenParts.length > 2 ? fenParts[2] : '-';
    String enPassant = fenParts.length > 3 ? fenParts[3] : '-';
    String halfmove = fenParts.length > 4 ? fenParts[4] : '0';
    String fullmove = fenParts.length > 5 ? fenParts[5] : '1';

    return '${ranks.join('/')} $activeColor $castling $enPassant $halfmove $fullmove';
  }

  String getChessPieceSymbol(String piece) {
    switch (piece) {
      case 'r':
        return '♜';
      case 'n':
        return '♞';
      case 'b':
        return '♝';
      case 'q':
        return '♛';
      case 'k':
        return '♚';
      case 'p':
        return '♟';
      case 'R':
        return '♖';
      case 'N':
        return '♘';
      case 'B':
        return '♗';
      case 'Q':
        return '♕';
      case 'K':
        return '♔';
      case 'P':
        return '♙';
      default:
        return '';
    }
  }

  Future<void> onSquareTap(int targetRow, int targetCol) async {
    List<List<String>> board = parseFenToBoard(currentFen);

    if (selectedRow == null && selectedCol == null) {
      if (board[targetRow][targetCol].isNotEmpty) {
        setState(() {
          selectedRow = targetRow;
          selectedCol = targetCol;
          statusMessage = 'เลือกตัวหมากแล้ว คลิกช่องเป้าหมายเพื่อเดิน';
        });
      }
      return;
    }

    if (selectedRow == targetRow && selectedCol == targetCol) {
      setState(() {
        selectedRow = null;
        selectedCol = null;
        statusMessage = 'ยกเลิกการเลือกหมาก';
      });
      return;
    }

    if (selectedRow != null && selectedCol != null) {
      String movedPiece = board[selectedRow!][selectedCol!];
      board[targetRow][targetCol] = movedPiece;
      board[selectedRow!][selectedCol!] = '';

      String newFen = generateFenFromBoard(board);

      setState(() {
        currentFen = newFen;
        selectedRow = null;
        selectedCol = null;
        statusMessage = 'ขยับตัวหมากเรียบร้อย! กำลังบันทึกลง Google Drive...';
      });

      await autoSaveToGoogleDrive(newFen);
    }
  }

  Future<void> autoSaveToGoogleDrive(String fenToSave) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      'https://chessflask-api.onrender.com/api/game/save-gdrive',
    );
    final payload = {
      'fen': fenToSave,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        setState(() {
          statusMessage =
              resData['message'] ?? 'บันทึกตาเดินลง Google Drive สำเร็จ!';
        });
      } else {
        setState(() {
          statusMessage = 'เกิดข้อผิดพลาดจาก Flask: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Catch Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> boardMatrix = parseFenToBoard(currentFen);

    // ดึงขนาดความกว้างและความสูงหน้าจอ
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // (ต่อให้เปิด Desktop Site บนมือถือ ถ้าจอเล็ก ก็จะแสดงผลแบบมือถือให้เต็มจอสวยงามครับ)
    bool isMobile = screenWidth < 600;
    double boardSize;

    if (isMobile) {
      // 2. เมื่อเปิดในมือถือ (แสดงผล Mobile site เต็มตา)
      boardSize = screenWidth * 0.95;
      if (boardSize > screenHeight * 0.65) {
        boardSize = screenHeight * 0.65;
      }
    } else {
      // 1. เมื่อเปิดในคอมพิวเตอร์ (แสดงผล Desktop site)
      boardSize = 500.0;
      if (boardSize > screenHeight * 0.7) {
        boardSize = screenHeight * 0.7;
      }
    }

    // คำนวณขนาดฟอนต์ของตัวหมากให้สัมพันธ์กับขนาดกระดาน
    double pieceFontSize = (boardSize / 8) * 0.65;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Game - Move & Auto Save to Google Drive'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: boardSize,
                height: boardSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown.shade800, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    int row = index ~/ 8;
                    int col = index % 8;
                    bool isDark = (row + col) % 2 == 1;
                    bool isSelected =
                        (selectedRow == row && selectedCol == col);
                    String piece = boardMatrix[row][col];

                    return GestureDetector(
                      onTap: isLoading ? null : () => onSquareTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.yellow.shade400
                              : (isDark
                                    ? Colors.brown.shade400
                                    : Colors.brown.shade100),
                          border: isSelected
                              ? Border.all(color: Colors.red, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            getChessPieceSymbol(piece),
                            style: TextStyle(
                              fontSize: pieceFontSize,
                              fontWeight: FontWeight.bold,
                              color: piece == piece.toUpperCase()
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: boardSize,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'สถานะ:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            if (isLoading)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('• $statusMessage'),
                        const SizedBox(height: 4),
                        Text(
                          'FEN: $currentFen',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
