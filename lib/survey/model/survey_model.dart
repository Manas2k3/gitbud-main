class SurveyQuestion {
  final String question;
  final Map<String, String> responses;
  final String resultCategory;
  final int stringResourceId;
  final String imageAsset; // path to the image asset (e.g. 'assets/images/smoking.png')

  SurveyQuestion({
    required this.question,
    required this.responses,
    required this.resultCategory,
    required this.stringResourceId,
    required this.imageAsset,
  });
}
