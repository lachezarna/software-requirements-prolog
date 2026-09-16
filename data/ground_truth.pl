% ============================================================
% ground_truth.pl
% Ръчно анотирана "златна колекция" (ground truth) от очакваните
% проблеми в примерния набор от изисквания (src/requirements_data.pl).
% Служи като база за количествена оценка на системата спрямо
% експертна (човешка) преценка - т. 5.3 "Оценка на резултатите
% и сравнение с други подходи".
%
% Всеки факт ground_truth_issue(Id, Type) означава: "изискване Id
% ДЕЙСТВИТЕЛНО има проблем от вид Type", независимо дали
% автоматичната система го открива или не.
% ============================================================

:- discontiguous ground_truth_issue/2.

% --- Пряко логическо противоречие ---
ground_truth_issue(req1, action_conflict).
ground_truth_issue(req2, action_conflict).

% --- Числово противоречие ---
ground_truth_issue(req5, numeric_conflict).
ground_truth_issue(req6, numeric_conflict).

% --- "Мека" несъгласуваност ---
ground_truth_issue(req8, soft_inconsistency).
ground_truth_issue(req9, soft_inconsistency).

% --- Нееднозначност ---
ground_truth_issue(req4, ambiguous).
ground_truth_issue(req12, ambiguous).

% --- Непълнота ---
ground_truth_issue(req4, incomplete).
ground_truth_issue(req10, incomplete).
ground_truth_issue(req12, incomplete).
ground_truth_issue(req13, incomplete).
ground_truth_issue(req14, incomplete).

% --- Циклична зависимост ---
ground_truth_issue(req13, dependency_cycle).
ground_truth_issue(req14, dependency_cycle).
