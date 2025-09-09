// survey/model/response_model.dart

class SurveyResponse {
  int marks;
  int resultCategory;
  int stringResourceId;

  // ✅ Already present in your app per your snippet
  String questionText;
  String selectedOption;

  // ✅ NEW: number of options for that question (used to map risk color)
  int optionsCount;

  SurveyResponse({
    required this.marks,
    required this.resultCategory,
    required this.stringResourceId,
    this.questionText = "",
    this.selectedOption = "",
    this.optionsCount = 4, // sensible default (Likert-4)
  });

  Map<String, dynamic> toJson() => {
    'marks': marks,
    'resultCategory': resultCategory,
    'stringResourceId': stringResourceId,
    'questionText': questionText,
    'selectedOption': selectedOption,
    'optionsCount': optionsCount, // ✅ NEW
  };

  factory SurveyResponse.fromJson(Map<String, dynamic> json) => SurveyResponse(
    marks: json['marks'] ?? 0,
    resultCategory: json['resultCategory'] ?? 0,
    stringResourceId: json['stringResourceId'] ?? 0,
    questionText: (json['questionText'] ?? "").toString(),
    selectedOption: (json['selectedOption'] ?? "").toString(),
    optionsCount: json['optionsCount'] is int ? json['optionsCount'] : 4,
  );
}
