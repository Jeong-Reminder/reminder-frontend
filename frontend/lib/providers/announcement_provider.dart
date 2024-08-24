import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/all/providers/models/board_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AnnouncementProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _boardList = []; // 전체 공지 리스트
  final List<String> _categoryList = []; // 경진대회 카테고리 리스트
  final List<Map<String, dynamic>> _cateBoardList = []; // 카테고리별 리스트
  Map<String, dynamic> _board = {}; // 하나의 게시글
  final List<Map<String, dynamic>> _hiddenList = []; // 숨김 게시글 리스트

  List<Map<String, dynamic>> get boardList => _boardList;
  List<String> get categoryList => _categoryList;
  List<Map<String, dynamic>> get cateBoardList => _cateBoardList;
  Map<String, dynamic> get board => _board;
  List<Map<String, dynamic>> get hiddenList => _hiddenList;

  // 엑세스 토큰 할당
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken'); // accessToken 키로 저장된 문자열 값을 가져옴
  }

  // final String baseUrl = 'http://10.0.2.2:9000/api/v1/announcement';
  final String baseUrl = 'http://127.0.0.1:9000/api/v1/announcement';

  // 게시글 작성
  Future<int> createBoard(
      Board board, List<File> pickedImages, List<File> pickedFiles) async {
    final accessToken = await getToken();
    if (accessToken == null) {
      throw Exception('엑세스 토큰을 찾을 수 없음');
    }

    final url = Uri.parse(baseUrl);
    final boardInfo = http.MultipartRequest('POST', url);

    // 엑세스 토큰 추가
    boardInfo.headers['access'] = accessToken;

    // 텍스트 데이터 추가
    boardInfo.fields['announcementCategory'] = board.announcementCategory!;
    boardInfo.fields['announcementTitle'] = board.announcementTitle!;
    boardInfo.fields['announcementContent'] = board.announcementContent!;
    boardInfo.fields['announcementImportant'] =
        board.announcementImportant.toString();
    boardInfo.fields['visible'] = board.visible.toString();
    boardInfo.fields['announcementLevel'] = board.announcementLevel.toString();

    // 이미지 파일 추가
    if (pickedImages.isNotEmpty) {
      for (var img in pickedImages) {
        var multipartFile = await http.MultipartFile.fromPath(
          'img',
          img.path,
          filename: path.basename(img.path),
        );
        boardInfo.files.add(multipartFile);
      }
    }

    // 일반 파일 추가
    if (pickedFiles.isNotEmpty) {
      print('pickedFiles: $pickedFiles');
      for (var file in pickedFiles) {
        var bytes = await file.readAsBytes();

        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: path.basename(file.path),
        );
        boardInfo.files.add(multipartFile);
      }
    }

    try {
      final response = await boardInfo.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseBody = jsonDecode(responseString);
        final Map<String, dynamic> dataResponse = responseBody['data'];

        print('작성 성공: $dataResponse - ${dataResponse['id']}');

        return dataResponse['id'];
      } else {
        print('작성 실패: ${response.statusCode} - $responseString');
        throw Exception();
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception();
    }
  }

  // 게시글 보이기
  Future<void> showedBoard(int announcementId) async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/show/$announcementId');
      final response = await http.put(
        url,
        headers: {
          'access': accessToken,
        },
      );

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(utf8Response);

      if (response.statusCode == 200) {
        print('숨김 보이기 성공: $jsonResponse');
      } else {
        print('숨김 보이기 실패: ${response.body}');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 하나의 게시글 조회
  Future<void> fetchOneBoard(int announcementId) async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/$announcementId');
      final response = await http.get(
        url,
        headers: {
          'access': accessToken,
        },
      );

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(utf8Response)
          as Map<String, dynamic>; // JSON 문자열을 Map 객체로 변환

      final dataResponse = jsonResponse['data']; // 'data' 키에 접근

      if (response.statusCode == 200) {
        _board = dataResponse;
        notifyListeners();
        print('조회 성공: $_board');
      } else {
        print('조회 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 게시글 전체 조회
  Future<void> fetchAllBoards() async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse(baseUrl);
      final response = await http.get(
        url,
        headers: {
          'access': accessToken,
        },
      );

      _boardList.clear();

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(utf8Response)
          as Map<String, dynamic>; // JSON 문자열을 Map 객체로 변환

      final dataResponse = jsonResponse['data']; // 'data' 키에 접근

      if (response.statusCode == 200) {
        // 각 항목이 Map<String, dynamic>이라고 가정하고 추가
        for (var data in dataResponse) {
          _boardList.add(data);
        }
        notifyListeners();
        print('조회 성공: $_boardList');
      } else {
        print('조회 실패: ${response.bodyBytes}');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deletedBoard(int announcementId) async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/$announcementId');
      final response = await http.delete(
        url,
        headers: {
          'access': accessToken,
        },
      );

      if (response.statusCode == 204) {
        print('삭제 성공: ${response.body}');
      } else {
        print('삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 카테고리별 조회
  Future<void> fetchCateBoard(String boardCategory) async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/category/$boardCategory');
      final response = await http.get(
        url,
        headers: {
          'access': accessToken,
        },
      );

      _cateBoardList.clear();

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(utf8Response) as Map<String, dynamic>;

      final dataResponse = jsonResponse['data'];

      if (response.statusCode == 200) {
        for (var data in dataResponse) {
          _cateBoardList.add(data);
        }

        print('조회 성공: $_cateBoardList');
      } else {
        print('조회 실패');
      }
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }

  // 게시글 숨김
  Future<void> hiddenBoard(
      Map<String, dynamic> board, int accouncementId) async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/hide/$accouncementId');
      final response = await http.put(
        url,
        headers: {
          'access': accessToken,
        },
      );

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(utf8Response)
          as Map<String, dynamic>; // JSON 문자열을 Map 객체로 변환

      final dataResponse = jsonResponse['data']; // 'data' 키에 접근

      if (response.statusCode == 200) {
        print('숨김 성공: $dataResponse');
      } else {
        print('숨김 실패');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 경진대회 카테고리 전체 조회
  Future<void> fetchContestCate() async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/contest-categort-name');
      final response = await http.get(
        url,
        headers: {
          'access': accessToken,
        },
      );

      // 호출됐을 때 새로운 데이터를 추가할 때 중복방지를 위해 clear 메소드로 구현
      _categoryList.clear();

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(utf8Response) as Map<String, dynamic>;

      final dataResponse = jsonResponse['data'];

      if (response.statusCode == 200) {
        for (var data in dataResponse) {
          _categoryList.add(data);
        }

        print('조회 성공: $_categoryList');
      } else {
        print('조회 실패');
      }
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }

  // 숨김 게시글 목록 조회
  Future<void> fetchHiddenBoard() async {
    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        throw Exception('엑세스 토큰을 찾을 수 없음');
      }

      final url = Uri.parse('$baseUrl/hidden');
      final response = await http.get(
        url,
        headers: {
          'access': accessToken,
        },
      );

      hiddenList.clear();

      final utf8Response = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(utf8Response) as Map<String, dynamic>;

      final dataResponse = jsonResponse['data'];

      if (response.statusCode == 200) {
        for (var data in dataResponse) {
          _hiddenList.add(data);
        }
        notifyListeners();

        print('숨김 조회 성공: $dataResponse');
      } else {
        print('숨김 조회 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print(e.toString());
    }
  }
}