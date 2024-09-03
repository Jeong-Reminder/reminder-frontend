import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:frontend/models/profile_model.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/setExperience_screen.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/widgets/field_list.dart';
import 'package:frontend/widgets/tool_list.dart';
import 'package:percent_indicator/percent_indicator.dart';

class SetSkillPage extends StatefulWidget {
  final String githubLink;
  final String hopeJob;
  const SetSkillPage(this.githubLink, this.hopeJob, {super.key});

  @override
  State<SetSkillPage> createState() => _SetSkillPageState();
}

class _SetSkillPageState extends State<SetSkillPage> {
  String developmentField = '';
  String developmentTool = '';

  List<Map<String, dynamic>> selectedFields = []; // 선택된 Field 리스트
  List<Map<String, dynamic>> selectedTools = []; // 선택된 Tools 리스트

  bool completedField = false; // Field 선택 완료 불리안
  double percent = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: FractionalOffset(percent, 1 - percent),
              child: Image.asset(
                'assets/images/cyclingPerson.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: LinearPercentIndicator(
                padding: EdgeInsets.zero,
                percent: percent,
                lineHeight: 20,
                backgroundColor: const Color(0xFFD9D9D9),
                progressColor: const Color(0xFF2A72E7),
                width: 370,
              ),
            ),
            const SizedBox(height: 60),
            Row(
              children: [
                const Text(
                  '기술 스택 지정하기',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var stack in selectedFields) {
                        stack['isSelected'] = false;
                      }
                      for (var tool in selectedTools) {
                        tool['isSelected'] = false;
                      }
                      selectedFields.clear();
                      selectedTools.clear();
                      completedField = false;
                    });
                  },
                  icon: const Icon(
                    Icons.restart_alt_outlined,
                    color: Colors.black,
                  ),
                  label: const Text(
                    '초기화',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            completedField
                ? const Text(
                    '2. DEVELOPMENT TOOLS 선택',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text(
                    '1. DEVELOPMENT FIELD 선택',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: const Offset(0, 0),
                    ),
                  ),
                  child: child,
                );
              },
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                return Stack(
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: completedField
                  ? Wrap(
                      key: ValueKey<bool>(completedField),
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.start,
                      spacing: 10,
                      runSpacing: 10,
                      children: toolsList.map((tools) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              tools['isSelected'] = !tools['isSelected'];
                              if (tools['isSelected']) {
                                selectedTools.add(tools);
                              } else {
                                selectedTools.remove(tools);
                              }
                            });
                            print('${tools['title']} : ${tools['isSelected']}');
                          },
                          child: badge(
                            tools['logoUrl'],
                            tools['title'],
                            tools['titleColor'],
                            tools['badgeColor'],
                            tools['isSelected'],
                          ),
                        );
                      }).toList(),
                    )
                  : Wrap(
                      key: ValueKey<bool>(completedField),
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.start,
                      spacing: 10,
                      runSpacing: 10,
                      children: fieldList.map((field) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              field['isSelected'] = !field['isSelected'];
                              if (field['isSelected']) {
                                selectedFields.add(field);
                              } else {
                                selectedFields.remove(field);
                              }
                            });
                            print('${field['title']} : ${field['isSelected']}');
                          },
                          child: badge(
                            field['logoUrl'],
                            field['title'],
                            field['titleColor'],
                            field['badgeColor'],
                            field['isSelected'],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Visibility(
        visible: completedField
            ? selectedTools.isNotEmpty
            : selectedFields.isNotEmpty,
        child: BottomSheet(
          onClosing: () {},
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height / 3.6,
          ),
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          builder: (context) {
            return Column(
              children: [
                SingleChildScrollView(
                  child: Container(
                    width: 400,
                    height: 160,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F6F6),
                    ),
                    child: completedField
                        ? Wrap(
                            direction: Axis.horizontal,
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedTools.map((tools) {
                              return badge(
                                tools['logoUrl'],
                                tools['title'],
                                tools['titleColor'],
                                tools['badgeColor'],
                                tools['isSelected'],
                              );
                            }).toList(),
                          )
                        : Wrap(
                            direction: Axis.horizontal,
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedFields.map((stack) {
                              return badge(
                                stack['logoUrl'],
                                stack['title'],
                                stack['titleColor'],
                                stack['badgeColor'],
                                stack['isSelected'],
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () async {
                    if (!completedField) {
                      setState(() {
                        completedField = true;

                        percent = 0.75;
                      });
                    } else {
                      setState(() {
                        // selectedFields에서 title들을 가져와 하나의 문자열로 생성
                        developmentField = selectedFields
                            .map((f) => f['title'])
                            .toList()
                            .join(',');

                        // selectedTools에서 title들을 가져와 하나의 문자열로 생성
                        developmentTool = selectedTools
                            .map((t) => t['title'])
                            .toList()
                            .join(','); // 요소 사이에 콤마(,) 추가
                      });

                      // body에 집어넣을 프로필 model
                      final profile = Profile(
                        hopeJob: widget.hopeJob,
                        githubLink: widget.githubLink,
                        developmentField: developmentField,
                        developmentTool: developmentTool,
                      );

                      print('profile: $profile');

                      try {
                        await ProfileProvider().createProfile(profile);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetExperiencePage(),
                            ),
                          );
                        }
                      } catch (e) {
                        print(e.toString());
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: const Color(0xFF2A72E7),
                    minimumSize: const Size(319, 46),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 기술 스택 배지
  Widget badge(
    String logoUrl,
    String title,
    Color titleColor,
    Color badgeColor,
    bool isSelected,
  ) {
    return badges.Badge(
      badgeContent: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              logoUrl,
              width: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
      ),
      badgeStyle: badges.BadgeStyle(
        badgeColor: badgeColor,
        shape: badges.BadgeShape.square,
        borderSide: isSelected
            ? const BorderSide(
                color: Color(0xFF2A72E7),
                width: 5.0,
              )
            : BorderSide.none,
      ),
    );
  }
}