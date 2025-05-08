class SurveyQuestion {
  final String question;
  final List<String> responses;
  final String resultCategory;
  final int stringResourceId;

  SurveyQuestion({
    required this.question,
    required this.responses,
    required this.resultCategory,
    required this.stringResourceId,
  });
}