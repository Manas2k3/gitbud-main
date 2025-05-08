class SurveyResponse {
  int marks;
  int resultCategory;
  int stringResourceId;

  SurveyResponse({
    required this.marks,
    required this.resultCategory,
    required this.stringResourceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'marks': marks,
      'resultCategory': resultCategory,
      'stringResourceId': stringResourceId,
    };
  }
}