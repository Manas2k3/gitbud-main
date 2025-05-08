  import '../../../survey/model/survey_model.dart';

  List<SurveyQuestion> surveyQuestions = [
    SurveyQuestion(
      question: "Do you smoke tobacco products?",
      responses: [
        "No tobacco use",
        "Rarely smoke",
        "Occasionally smoke",
        "Regular smoker"
      ],
      resultCategory: "Tobacco Use",
      stringResourceId: 2131820779,
    ),
    SurveyQuestion(
      question: "How would you describe your alcohol consumption?",
      responses: [
        "Non-drinker",
        "Occasional drinker",
        "Moderate drinker",
        "Heavy drinker"
      ],
      resultCategory: "Alcohol Use",
      stringResourceId: 2131820780,
    ),
    SurveyQuestion(
      question: "Have you experienced anxiety or depression symptoms related to your digestive health issues?",
      responses: [
        "Not at all",
        "Occasionally",
        "Frequently",
        "Severely"
      ],
      resultCategory: "Anxiety, depression",
      stringResourceId: 2131820781,
    ),
    SurveyQuestion(
      question: "Do you have any health conditions run in your family, e.g., diabetes, high blood pressure?",
      responses: [
        "No family history",
        "Some family history",
        "Uncertain",
        "Extensive family history"
      ],
      resultCategory: "Family History",
      stringResourceId: 2131820782,
    ),
    SurveyQuestion(
      question: "Has your stomach felt BLOATED during the past week? (Feeling bloated refers to swelling often associated with a sensation of gas or air in the stomach.)",
      responses: [
        "No discomfort at all",
        "Mild discomfort",
        "Moderate discomfort",
        "Severe discomfort"
      ],
      resultCategory: "Bloating",
      stringResourceId: 2131820783,
    ),
    SurveyQuestion(
      question: "Have you been bothered by CONSTIPATION during the past week? (Constipation refers to a reduced ability to empty the bowels.)",
      responses: [
        "No discomfort at all",
        "Mild discomfort",
        "Moderate discomfort",
        "Severe discomfort"
      ],
      resultCategory: "Constipation",
      stringResourceId: 2131820784,
    ),
    SurveyQuestion(
      question: "How often do you exercise (for at least 30 minutes) to a level where you’d become short of breath if you tried to sing?",
      responses: [
        "Daily",
        "Regularly",
        "Occasionally",
        "Rarely or Never"
      ],
      resultCategory: "Physical Activity",
      stringResourceId: 2131820785,
    ),
    SurveyQuestion(
      question: "Do you have any environmental factors that may affect your gut health, such as exposure to pollutants or toxins?",
      responses: [
        "No environmental factors",
        "Some exposure",
        "Frequent exposure",
        "Constant exposure"
      ],
      resultCategory: "Environmental Stress",
      stringResourceId: 2131820786,
    ),
    SurveyQuestion(
      question: "How often are you unwell, e.g., with colds and flu?",
      responses: [
        "Rarely",
        "Occasionally",
        "Frequently",
        "Constantly"
      ],
      resultCategory: "Fever, nausea",
      stringResourceId: 2131820787,
    ),
    SurveyQuestion(
      question: "How often are you negatively impacted by stress?",
      responses: [
        "Rarely",
        "Occasionally",
        "Frequently",
        "Constantly"
      ],
      resultCategory: "Stress Levels",
      stringResourceId: 2131820788,
    ),
    SurveyQuestion(
      question: "Do you take regular medication?",
      responses: [
        "No regular medication",
        "Some regular medication",
        "Frequent regular medication",
        "Constant regular medication"
      ],
      resultCategory: "Medication Stress",
      stringResourceId: 2131820789,
    ),
    SurveyQuestion(
      question: "Do you experience any digestive symptoms (e.g., bloating, constipation, diarrhea) in the days leading up to your period?",
      responses: [
        "No symptoms",
        "Occasionally",
        "Frequently",
        "Constantly"
      ],
      resultCategory: "Digestive Issues",
      stringResourceId: 2131820790,
    ),
    SurveyQuestion(
      question: "Have you been diagnosed with any specific conditions by a doctor? (Select all that apply)",
      responses: [
        "None",
        "One condition",
        "Multiple conditions",
        "Chronic conditions"
      ],
      resultCategory: "Diagnosed Conditions",
      stringResourceId: 2131820791,
    ),
  ];
