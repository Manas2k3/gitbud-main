import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:gibud/controllers/survey_controller.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/survey/model/survey_model.dart';
import 'package:gibud/utils/popups/loaders.dart';
import 'package:iconsax/iconsax.dart';
import '../data/repositories/survey/survey_questions.dart';
import 'survey_result.dart';

class SurveyScreen extends StatefulWidget {
  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final SurveyController surveyController = Get.put(SurveyController());
  final PageController _pageController = PageController();
  Map<int, String> selectedResponses = {};
  int currentIndex = 0;
  String? gender;

  @override
  void initState() {
    super.initState();
    _fetchUserGender();
  }

  Future<void> _fetchUserGender() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      setState(() {
        gender = userDoc['gender'];
      });
    }
  }

  List<SurveyQuestion> _filteredQuestions() {
    return surveyQuestions.where((q) {
      return !(q.stringResourceId == 2131820790 && gender != 'Female');
    }).toList();
  }

  bool _isAnswered(int index) => selectedResponses.containsKey(index);

  void _selectAnswer(SurveyQuestion question, int index, String responseKey) {
    setState(() {
      selectedResponses[index] = responseKey;
      int marks = _getMarksFromResponse(question, responseKey);
      surveyController.selectAnswer(index, marks, question);
    });

    if (index < _filteredQuestions().length - 1) {
      Future.delayed(Duration(milliseconds: 300), () {
        _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  int _getMarksFromResponse(SurveyQuestion question, String responseKey) {
    final keys = question.responses.keys.map((e) => e.trim()).toList();
    final index = keys.indexOf(responseKey.trim());
    return index != -1 ? index + 1 : 0;
  }

  Future<void> _submitSurvey(BuildContext context) async {
    int required = _filteredQuestions().length;
    if (selectedResponses.length == required) {
      await surveyController.submitSurvey(context);
      Get.to(SurveyResultScreen(
        responses: selectedResponses,
        calculatedTotalScore: surveyController.totalScore.value,
        questions: _filteredQuestions(),
      ));
    } else {
      Loaders.warningSnackBar(title: "Incomplete", message: "Please answer all questions.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _filteredQuestions();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(onPressed: () => Get.offAll(NavigationMenu()), icon: Icon(Icons.arrow_back)),
        title: Text("Survey Page", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      backgroundColor: Colors.white,
      body: gender == null
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              'Question ${currentIndex + 1}/${questions.length}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(50),
                minHeight: MediaQuery.of(context).size.height * 0.006,
                value: (currentIndex + 1) / questions.length,
                color: Colors.black,
                backgroundColor: Colors.grey.shade400,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                physics: BouncingScrollPhysics(),
                onPageChanged: (newIndex) {
                  final prevIndex = currentIndex;
                  if (newIndex > prevIndex && !_isAnswered(prevIndex)) {
                    _pageController.animateToPage(
                      prevIndex,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                    Loaders.warningSnackBar(
                      title: "Response required",
                      message: "Please select an option to continue.",
                    );
                    return;
                  }
                  setState(() => currentIndex = newIndex);
                },
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _buildQuestionCard(question, index)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentIndex > 0)
              ElevatedButton(
                onPressed: () => _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (currentIndex == questions.length - 1)
              ElevatedButton(
                onPressed: () => _submitSurvey(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion question, int index) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(
                  question.imageAsset.isNotEmpty
                      ? question.imageAsset
                      : 'assets/images/placeholder.png',
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 30),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: question.responses.entries.map((entry) {
              String responseKey = entry.key;
              bool isSelected = selectedResponses[index] == responseKey;

              return GestureDetector(
                onTap: () => _selectAnswer(question, index, responseKey),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    responseKey,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
