import '../../../survey/model/survey_model.dart';

List<SurveyQuestion> surveyQuestions = [
  SurveyQuestion(
    question: "How many cigarettes do you smoke in a day?",
    responses: {
      "0": "No tobacco use",
      "1 to 2": "Rarely smoke",
      "3 to 5": "Occasionally smoke",
      "6 to 10": "Regular smoker",
    },
    resultCategory: "Tobacco Use",
    stringResourceId: 2131820779,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how would you describe your alcohol consumption (weekly)?",
    responses: {
      "0": "Nontodrinker",
      "1": "Occasional drinker",
      "2": "Moderate drinker",
      "3": "Heavy drinker",
    },
    resultCategory: "Alcohol Use",
    stringResourceId: 2131820780,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how severely have you experienced anxiety or depression symptoms related to digestive health?",
    responses: {
      "0": "Not at all",
      "1": "Occasionally",
      "2": "Frequently",
      "3": "Severely",
    },
    resultCategory: "Anxiety, depression",
    stringResourceId: 2131820781,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how significant is your family history of health conditions (e.g., diabetes, high blood pressure)?",
    responses: {
      "0": "No family history",
      "1": "Some family history",
      "2": "Uncertain",
      "3": "Extensive family history",
    },
    resultCategory: "Family History",
    stringResourceId: 2131820782,
  ),
  SurveyQuestion(
    question: "How many times have you felt bloated during the past week?",
    responses: {
      "0": "No discomfort at all",
      "1 to 2": "Mild discomfort",
      "3 to 5": "Moderate discomfort",
      "5 to 7 or more ": "Severe discomfort",
    },
    resultCategory: "Bloating",
    stringResourceId: 2131820783,
  ),
  SurveyQuestion(
    question: "How many times have you been bothered by constipation during the past week?",
    responses: {
      "0": "No discomfort at all",
      "1 to 2": "Mild discomfort",
      "3 to 5": "Moderate discomfort",
      "5 to 7": "Severe discomfort",
    },
    resultCategory: "Constipation",
    stringResourceId: 2131820784,
  ),
  SurveyQuestion(
    question: "In a typical week, how often do you engage in physical activity intense enough to make you short of breath if you tried to sing?",
    responses: {
      "5 to 7 days": "Daily",
      "3 to 5 days": "Regularly",
      "1 to 2 days": "Occasionally",
      "Never": "Rarely or never",
    },
    resultCategory: "Physical Activity",
    stringResourceId: 2131820785,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how much exposure do you have to environmental factors (pollutants or toxins) that may affect your gut health?",
    responses: {
      "0": "No environmental exposure",
      "1": "Some exposure",
      "2": "Frequent exposure",
      "3": "Constant exposure",
    },
    resultCategory: "Environmental Stress",
    stringResourceId: 2131820786,
  ),
  SurveyQuestion(
    question: "How often are you unwell (e.g., with colds or flu) in a typical week?",
    responses: {
      "0": "Rarely",
      "1 to 2 days": "Occasionally",
      "3 to 5 days": "Frequently",
      "5 to 7 days": "Constantly",
    },
    resultCategory: "Fever, nausea",
    stringResourceId: 2131820787,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how often is your routine or digestion negatively affected by stress?",
    responses: {
      "0": "Rarely",
      "1": "Occasionally",
      "2": "Frequently",
      "3": "Constantly",
    },
    resultCategory: "Stress Levels",
    stringResourceId: 2131820788,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how frequently do you take regular medication in a typical week?",
    responses: {
      "0": "No regular medication",
      "1": "Occasional medication",
      "2": "Frequent medication",
      "3": "Daily or constant medication",
    },
    resultCategory: "Medication Stress",
    stringResourceId: 2131820789,
  ),
  SurveyQuestion(
    question: "On a scale of 0–3, how often do you experience digestive symptoms before your period (e.g., bloating, constipation, diarrhea)?",
    responses: {
      "0": "No symptoms",
      "1": "Occasionally",
      "2": "Frequently",
      "3": "Constantly",
    },
    resultCategory: "Digestive Issues",
    stringResourceId: 2131820790,
  ),
  SurveyQuestion(
    question: "How many medical conditions have you been formally diagnosed with by a doctor?",
    responses: {
      "None": "None",
      "1": "One condition",
      "2 to 3": "A few conditions (2–3)",
      "4 or more": "Several or chronic conditions (4+)",
    },
    resultCategory: "Diagnosed Conditions",
    stringResourceId: 2131820791,
  ),
];

