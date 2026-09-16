% ============================================================
% evaluation.pl
% Количествена оценка на системата спрямо ръчно анотиран тестов
% набор (data/ground_truth.pl) и сравнение с наивен базов подход
% (само претърсване по ключови думи, без логически извод).
% Съответства на т. 5.3 "Оценка на резултатите и сравнение с
% други подходи".
% ============================================================

:- ensure_loaded(kb_schema).
:- ensure_loaded(requirements_data).
:- ensure_loaded(conflict_rules).
:- ensure_loaded(recommendations).
:- ensure_loaded('../data/ground_truth').

% ============================================================
% Множества от двойки (Id, ТипПроблем) за сравнение
% ============================================================

%! all_system_issue_pairs(-Pairs) is det.
%  Уникални двойки, открити от логическата Prolog система.
all_system_issue_pairs(Pairs) :-
    findall(Id-Type, requirement_issue(Id, Type, _), Pairs0),
    sort(Pairs0, Pairs).

%! all_ground_truth_pairs(-Pairs) is det.
all_ground_truth_pairs(Pairs) :-
    findall(Id-Type, ground_truth_issue(Id, Type), Pairs0),
    sort(Pairs0, Pairs).

%! all_baseline_pairs(-Pairs) is det.
%  Наивен базов подход: претърсва само текста на изискването за
%  нееднозначни термини (без структурирано представяне на
%  действия/атрибути и без логически извод между изисквания).
%  Не е в състояние по принцип да открие противоречия, цикли или
%  непълнота, защото те изискват съпоставяне между различни
%  изисквания, а не анализ на едно изречение поотделно.
all_baseline_pairs(Pairs) :-
    findall(Id-ambiguous,
        ( requirement(Id, _, _, _, _, _),
          once(baseline_ambiguous(Id))
        ),
        Pairs0),
    sort(Pairs0, Pairs).

baseline_ambiguous(Id) :-
    requirement(Id, _, Text, _, _, _),
    ambiguous_term(Term),
    sub_string_ci(Text, Term).

% ============================================================
% Метрики: precision, recall, F1
% ============================================================

%! evaluate(+Detected, +Truth, -Metrics) is det.
%  Metrics = metrics(Precision, Recall, F1, TP, FP, FN, TPList, FPList, FNList)
evaluate(Detected, Truth, metrics(Precision, Recall, F1, TP, FP, FN, TPList, FPList, FNList)) :-
    intersection(Detected, Truth, TPList), length(TPList, TP),
    subtract(Detected, Truth, FPList), length(FPList, FP),
    subtract(Truth, Detected, FNList), length(FNList, FN),
    length(Detected, NDetected),
    length(Truth, NTruth),
    ( NDetected =:= 0 -> Precision = 0.0 ; Precision is TP / NDetected ),
    ( NTruth =:= 0    -> Recall = 0.0    ; Recall is TP / NTruth ),
    ( Precision + Recall =:= 0
    -> F1 = 0.0
    ;  F1 is 2 * Precision * Recall / (Precision + Recall)
    ).

%! filter_by_type(+Type, +Pairs, -Filtered) is det.
filter_by_type(Type, Pairs, Filtered) :-
    findall(Id-Type, member(Id-Type, Pairs), Filtered).

% ============================================================
% Отчет за оценката
% ============================================================

print_evaluation_report :-
    all_system_issue_pairs(SysPairs),
    all_ground_truth_pairs(TruthPairs),
    all_baseline_pairs(BasePairs),
    length(TruthPairs, NTruth),
    evaluate(SysPairs, TruthPairs, SysMetrics),
    evaluate(BasePairs, TruthPairs, BaseMetrics),

    format("~n=== ОЦЕНКА НА РЕЗУЛТАТИТЕ ===~n"),
    format("Ръчно анотирани (ground truth) проблеми в тестовия набор: ~w~n", [NTruth]),

    format("~n--- Подход 1: Prolog система (логически извод) ---~n"),
    print_metrics(SysMetrics),

    format("~n--- Подход 2: базово претърсване по ключови думи ---~n"),
    format("(без структурирано представяне и без извод между изисквания)~n"),
    print_metrics(BaseMetrics),

    format("~n--- Покритие по тип проблем (recall по категория) ---~n"),
    format("~w~t~25|~w~t~45|~w~n", ['Тип проблем', 'Prolog система', 'Базов подход']),
    forall(member(Type, [action_conflict, numeric_conflict, soft_inconsistency,
                          ambiguous, incomplete, dependency_cycle]),
        print_category_row(Type, SysPairs, BasePairs, TruthPairs)),

    print_false_negatives(SysMetrics),

    filter_by_type(ambiguous, TruthPairs, TruthAmbiguous),
    length(TruthAmbiguous, NTruthAmbiguous),
    NUnreachableByBaseline is NTruth - NTruthAmbiguous,

    format("~n--- Извод ---~n"),
    format("Базовият подход открива изключително нееднозначни термини в изречения~n"),
    format("поотделно и не разполага със структурирано представяне на действия и~n"),
    format("количествени атрибути (action/5, attribute/5), нито с механизъм за~n"),
    format("логически извод между отделни изисквания. Затова той структурно не е~n"),
    format("способен да открие противоречия, числови несъвместимости или циклични~n"),
    format("зависимости - категории, съставляващи ~w от общо ~w ground truth проблема.~n",
        [NUnreachableByBaseline, NTruth]).

print_metrics(metrics(P, R, F1, TP, FP, FN, _, _, _)) :-
    format("  Precision: ~2f  (TP=~w, FP=~w)~n", [P, TP, FP]),
    format("  Recall:    ~2f  (TP=~w, FN=~w)~n", [R, TP, FN]),
    format("  F1-score:  ~2f~n", [F1]).

print_category_row(Type, SysPairs, BasePairs, TruthPairs) :-
    filter_by_type(Type, TruthPairs, TruthCat),
    length(TruthCat, NTruthCat),
    filter_by_type(Type, SysPairs, SysCat),
    intersection(SysCat, TruthCat, SysTP),
    length(SysTP, NSysTP),
    filter_by_type(Type, BasePairs, BaseCat),
    intersection(BaseCat, TruthCat, BaseTP),
    length(BaseTP, NBaseTP),
    format("~w~t~25|~w/~w~t~45|~w/~w~n", [Type, NSysTP, NTruthCat, NBaseTP, NTruthCat]).

print_false_negatives(metrics(_, _, _, _, _, _, _, _, [])) :-
    !,
    format("~n--- Пропуснати от Prolog системата: няма (recall = 100%) ---~n").
print_false_negatives(metrics(_, _, _, _, _, _, _, _, FNList)) :-
    format("~n--- Пропуснати от Prolog системата (false negatives) ---~n"),
    forall(member(Id-Type, FNList), format("  ~w : ~w~n", [Id, Type])).
