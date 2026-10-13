import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/quiz_model.dart';

final quizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/quizzes.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

final currentQuizProvider =
    StateNotifierProvider<QuizSessionNotifier, QuizSessionState>((ref) {
      return QuizSessionNotifier();
    });

class QuizSessionState {
  final QuizModel? quiz;
  final int currentQuestionIndex;
  final int score;
  final bool isFinished;
  final bool isAnswered;
  final int? selectedOptionIndex;

  QuizSessionState({
    this.quiz,
    this.currentQuestionIndex = 0,
    this.score = 0,
    this.isFinished = false,
    this.isAnswered = false,
    this.selectedOptionIndex,
  });

  QuizSessionState copyWith({
    QuizModel? quiz,
    int? currentQuestionIndex,
    int? score,
    bool? isFinished,
    bool? isAnswered,
    int? selectedOptionIndex,
  }) {
    return QuizSessionState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      isFinished: isFinished ?? this.isFinished,
      isAnswered: isAnswered ?? this.isAnswered,
      selectedOptionIndex: selectedOptionIndex,
    );
  }
}

class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  QuizSessionNotifier() : super(QuizSessionState());

  void startQuiz(QuizModel quiz) {
    state = QuizSessionState(quiz: quiz);
  }

  void answerQuestion(int optionIndex) {
    if (state.isAnswered || state.quiz == null) return;

    final currentQ = state.quiz!.questions[state.currentQuestionIndex];
    final isCorrect = optionIndex == currentQ.correctOptionIndex;

    state = state.copyWith(
      isAnswered: true,
      selectedOptionIndex: optionIndex,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  void nextQuestion() {
    if (!state.isAnswered || state.quiz == null) return;

    if (state.currentQuestionIndex < state.quiz!.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        isAnswered: false,
        selectedOptionIndex: null, // Clear selection
      );
    } else {
      state = state.copyWith(isFinished: true);
    }
  }

  void reset() {
    state = QuizSessionState(quiz: state.quiz);
  }
}
