import 'package:flutter/material.dart';
import 'package:frontend/all/providers/announcement_provider.dart';
import 'package:frontend/screens/write_screen.dart';
import 'package:frontend/services/login_services.dart';
import 'package:frontend/widgets/boardAppbar_widget.dart';
import 'package:frontend/widgets/board_widget.dart';
import 'package:provider/provider.dart';

class GradeBoardPage extends StatefulWidget {
  const GradeBoardPage({super.key});

  @override
  State<GradeBoardPage> createState() => _GradeBoardPageState();
}

enum PopUpItem { popUpItem1, popUpItem2, popUpItem3 }

class _GradeBoardPageState extends State<GradeBoardPage> {
  String selectedGrade = '1학년';
  bool isSelected = false;
  bool isHidDel = false; // 숨김 / 삭제 버튼 숨김 활성화 불리안
  Map<String, dynamic>? selectedBoard; // 선택된 게시글을 저장할 변수

  String userRole = '';
  String boardCategory = 'ACADEMIC_ALL';
  int gradeCategory = 1; // 학년 버튼을 눌렀을 때 해당하는 학년을 저장하는 변수
  List<int> gradeList = [1, 2, 3, 4];

  // 숨김 해제 시 호출되는 함수
  // void unhideItems(List<Map<String, dynamic>> items) {
  //   setState(() {
  //     for (var item in items) {
  //       item['isChecked'] = false;
  //       // 각 학년별 게시판 리스트 (oneBoard, twoBoard, threeBoard, fourBoard)를 정의
  //       // 각 항목에 originalIndex를 추가하여 원래 인덱스를 저장
  //       // 각 항목의 originalIndex를 사용하여 원래 인덱스 위치에 항목을 다시 추가
  //       if (selectedGrade == '1학년') {
  //         oneBoard.insert(item['originalIndex'], item);
  //       } else if (selectedGrade == '2학년') {
  //         twoBoard.insert(item['originalIndex'], item);
  //       } else if (selectedGrade == '3학년') {
  //         threeBoard.insert(item['originalIndex'], item);
  //       } else if (selectedGrade == '4학년') {
  //         fourBoard.insert(item['originalIndex'], item);
  //       }
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementProvider>(context, listen: false)
          .fetchCateBoard(boardCategory);
    });

    _loadCredentials();
  }

  // 역할을 로드하는 메서드
  Future<void> _loadCredentials() async {
    final loginAPI = LoginAPI(); // LoginAPI 인스턴스 생성
    final credentials = await loginAPI.loadCredentials(); // 저장된 자격증명 로드
    setState(() {
      userRole = credentials['userRole']; // 로그인 정보에 있는 level를 가져와 저장
    });
  }

  @override
  Widget build(BuildContext context) {
    // 해당 공지 카테고리의 공지 리스트 출력
    final gradeBoardList =
        Provider.of<AnnouncementProvider>(context).cateBoardList;

    // gradeCategory와 일치하는 공지만 필터링
    final filteredBoardList = gradeBoardList.where((board) {
      final gradeLevel = board['announcementLevel'];
      return gradeLevel == gradeCategory;
    }).toList();

    return Scaffold(
      appBar: const BoardAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학년 공지 상단바
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '학년 공지',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 팝업 메뉴 창
                PopupMenuButton<PopUpItem>(
                  color: const Color(0xFFEFF0F2),
                  itemBuilder: (BuildContext context) {
                    return [
                      if (userRole == 'ROLE_ADMIN')
                        popUpItem('글쓰기', PopUpItem.popUpItem1, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BoardWritePage()),
                          );
                        }),
                      if (userRole == 'ROLE_ADMIN') const PopupMenuDivider(),
                      popUpItem('새로고침', PopUpItem.popUpItem2, () {}),
                      if (userRole == 'ROLE_ADMIN') const PopupMenuDivider(),
                      if (userRole == 'ROLE_ADMIN')
                        popUpItem('숨김 관리', PopUpItem.popUpItem3, () {
                          // 숨김 페이지로 이동
                        }),
                    ];
                  },
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 학년 별 카테고리 버튼
            SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: gradeList.length,
                itemBuilder: (context, index) {
                  final grade = gradeList[index];

                  return Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            gradeCategory = grade;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDBE7FB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          surfaceTintColor: const Color(0xFFAFCAF6),
                        ),
                        child: Text(
                          '$grade학년',
                          style: TextStyle(
                            // gradeCategory와 버튼의 학년이 일치하면 검은색 글씨로 설정
                            color: (gradeCategory == grade)
                                ? Colors.black
                                : Colors.black.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Board(
                  boardList: filteredBoardList,
                  total: false,
                  onBoardSelected: (board) {
                    setState(() {
                      selectedBoard = board;
                      isHidDel = !isHidDel;
                    });
                  }),
            ),
          ],
        ),
      ),

      // 숨김/삭제 버튼(isEdited 값을 저장한 isHidDel)
      bottomNavigationBar: isHidDel
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAFAFE),
                    minimumSize: const Size(205, 75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: const Text(
                    '숨김',
                    style: TextStyle(
                      color: Color(0xFF7D7D7F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedBoard != null) {
                      print('id: ${selectedBoard!['id']}');
                      await Provider.of<AnnouncementProvider>(context,
                              listen: false)
                          .deletedBoard(selectedBoard!['id']);

                      if (context.mounted) {
                        await Provider.of<AnnouncementProvider>(context,
                                listen: false)
                            .fetchCateBoard(boardCategory);
                      }

                      setState(() {
                        isHidDel = true;
                        selectedBoard = null;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAFAFE),
                    minimumSize: const Size(205, 75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      color: Color(0xFF7D7D7F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

PopupMenuItem<PopUpItem> popUpItem(
    String text, PopUpItem item, Function() onTap) {
  return PopupMenuItem<PopUpItem>(
    enabled: true, // 팝업메뉴 호출(ex: onTap()) 가능
    onTap: onTap,
    value: item,
    height: 25,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF787879),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}