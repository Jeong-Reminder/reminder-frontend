import 'package:flutter/material.dart';
import 'package:frontend/providers/announcement_provider.dart';
import 'package:frontend/screens/hiddenList_screen.dart';
import 'package:frontend/screens/write_screen.dart';
import 'package:frontend/services/login_services.dart';
import 'package:frontend/widgets/boardAppbar_widget.dart';
import 'package:frontend/widgets/board_widget.dart';
import 'package:provider/provider.dart';

class CorSeaBoardPage extends StatefulWidget {
  const CorSeaBoardPage({super.key});

  @override
  State<CorSeaBoardPage> createState() => _CorSeaBoardPageState();
}

enum PopUpItem { popUpItem1, popUpItem2, popUpItem3 }

class _CorSeaBoardPageState extends State<CorSeaBoardPage> {
  bool isHidDel = false;

  String userRole = '';

  Map<String, dynamic>? selectedBoard;

  List<String> boardCategory = ['CORPORATE_TOUR', 'SEASONAL_SYSTEM'];
  List<Map<String, dynamic>> corporateBoardList = [];
  List<Map<String, dynamic>> seasonalBoardList = [];

  // 2년 된 게시글 1월 1일에 삭제되는 함수
  void delete2YearsBoard(List<Map<String, dynamic>> boardList) async {
    DateTime now = DateTime.now(); // 현재 시간 생성
    final announcementProvider =
        Provider.of<AnnouncementProvider>(context, listen: false);

    // 현재 시간이 1월 1일인지 확인
    if (now.month == 1 && now.day == 1) {
      for (var board in boardList) {
        final DateTime createdTime =
            DateTime.parse(board['createdTime']); // 게시글 생성시간 생성
        final Duration difference =
            now.difference(createdTime); // 현재시간과 게시글 생성시간 차이

        // 게시글이 2년 지나면 게시글 삭제
        if (difference.inDays >= 730) {
          await announcementProvider.deletedBoard(board['id']);
        }
      }

      // 2년 이상된 게시글을 찾아 삭제를 완료할 경우 전체 게시글 조회
      if (context.mounted) {
        for (var cate in boardCategory) {
          await announcementProvider.fetchCateBoard(cate);
        }
      }
    } else {
      print('오늘은 1월 1일이 아닙니다. 게시글 삭제가 실행되지 않았습니다.');
    }
  }

  @override
  void initState() {
    super.initState();
    // listen: false를 사용하여 initState에서 Provider를 호출
    // addPostFrameCallback 사용하는 이유 : initState에서 직접 Provider.of를 호출할 때 context가 아직 완전히 준비되지 않았기 때문에 발생할 수 있는 에러를 방지
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 첫 번째 카테고리 API 호출
      await Provider.of<AnnouncementProvider>(context, listen: false)
          .fetchCateBoard(boardCategory[0]);

      setState(() {
        // 깊은 복사를 위해 List<Map<String, dynamic>>.from을 사용
        // 이로 인해 cateBoardList가 변하더라도 corporateBoardList와 seasonalBoardList는 영향을 받지 않음
        corporateBoardList = List<Map<String, dynamic>>.from(
            Provider.of<AnnouncementProvider>(context, listen: false)
                .cateBoardList); // cateBoardList를 corporateBoardList에 복사
        print('corporateBoardList: $corporateBoardList');
      });

      if (context.mounted) {
        // 두 번째 카테고리 API 호출
        await Provider.of<AnnouncementProvider>(context, listen: false)
            .fetchCateBoard(boardCategory[1]);

        setState(() {
          seasonalBoardList = List<Map<String, dynamic>>.from(
              Provider.of<AnnouncementProvider>(context, listen: false)
                  .cateBoardList); // cateBoardList를 seasonalBoardList에 복사
          print('seasonalBoardList: $seasonalBoardList');
        });
      }
    });
    // 게시글 카테고리가 2개 있는 페이지이기 때문에 2번 호출
    delete2YearsBoard(corporateBoardList);
    delete2YearsBoard(seasonalBoardList);

    _loadCredentials();
  }

  // 학번, 이름, 재적상태를 로드하는 메서드
  Future<void> _loadCredentials() async {
    final loginAPI = LoginAPI(); // LoginAPI 인스턴스 생성
    final credentials = await loginAPI.loadCredentials(); // 저장된 자격증명 로드
    setState(() {
      userRole = credentials['userRole']; // 로그인 정보에 있는 level를 가져와 저장
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sumList = List.from(corporateBoardList)
      ..addAll(seasonalBoardList);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BoardAppbar(
        userRole: userRole,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30.0,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '기업탐방 ⋅ 계절제 공지',
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
                              builder: (context) =>
                                  const BoardWritePage(category: 'CORSEA'),
                            ),
                          );
                        }),
                      if (userRole == 'ROLE_ADMIN') const PopupMenuDivider(),
                      popUpItem('새로고침', PopUpItem.popUpItem2, () {}),
                      if (userRole == 'ROLE_ADMIN') const PopupMenuDivider(),
                      if (userRole == 'ROLE_ADMIN')
                        popUpItem('숨김 관리', PopUpItem.popUpItem3, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HiddenPage(category: 'CORSEA'),
                            ),
                          );
                        }),
                    ];
                  },
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Board(
                boardList: sumList,
                total: true,
                onBoardSelected: (board) {
                  setState(() {
                    selectedBoard = board;
                    isHidDel = !isHidDel;
                  });
                },
                category: 'CORSEA',
              ),
            ),
          ],
        ),
      ),

      // 숨김/삭제 버튼(isEdited 값을 저장한 isHidDel)
      bottomNavigationBar: isHidDel
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 12,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedBoard != null) {
                        print('id: ${selectedBoard!['id']}');
                        await Provider.of<AnnouncementProvider>(context,
                                listen: false)
                            .hiddenBoard(selectedBoard!, selectedBoard!['id']);

                        if (context.mounted) {
                          await Provider.of<AnnouncementProvider>(context,
                                  listen: false)
                              .fetchCateBoard(boardCategory[0]);
                        }

                        if (context.mounted) {
                          // 두 번째 카테고리 API 호출
                          await Provider.of<AnnouncementProvider>(context,
                                  listen: false)
                              .fetchCateBoard(boardCategory[1]);
                        }

                        setState(() {
                          isHidDel = false; // 숨김/삭제 버튼 숨기기
                          selectedBoard = null; // 선택된 게시글 초기화
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
                      '숨김',
                      style: TextStyle(
                        color: Color(0xFF7D7D7F),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 12,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedBoard != null) {
                        print('id: ${selectedBoard!['id']}');
                        await Provider.of<AnnouncementProvider>(context,
                                listen: false)
                            .deletedBoard(selectedBoard!['id']);

                        if (context.mounted) {
                          await Provider.of<AnnouncementProvider>(context,
                                  listen: false)
                              .fetchCateBoard(boardCategory[0]);
                        }

                        if (context.mounted) {
                          // 두 번째 카테고리 API 호출
                          await Provider.of<AnnouncementProvider>(context,
                                  listen: false)
                              .fetchCateBoard(boardCategory[1]);
                        }

                        setState(() {
                          selectedBoard = null;
                          isHidDel = false;
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
