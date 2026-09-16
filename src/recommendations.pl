% ============================================================
% recommendations.pl
% Модул за генериране на препоръки на база откритите проблеми
% от conflict_rules.pl. Съответства на т. 4.3 "Модул за
% генериране на препоръки (на база откритите проблеми)".
% ============================================================

:- ensure_loaded(kb_schema).
:- ensure_loaded(conflict_rules).

% ============================================================
% Тежест (severity) на всеки тип проблем
% ============================================================

severity(action_conflict,   critical).
severity(numeric_conflict,  critical).
severity(dependency_cycle,  critical).
severity(soft_inconsistency, medium).
severity(ambiguous,         medium).
severity(incomplete,        low).

% Числов ранг на тежестта - по-малкото число = по-важно.
severity_rank(critical, 1).
severity_rank(high,     2).
severity_rank(medium,   3).
severity_rank(low,      4).

% ============================================================
% Текст на съобщението и предложената корекция за всеки тип
% проблем. Използва детайлите (Details), върнати от
% requirement_issue/3 в conflict_rules.pl.
% ============================================================

%! issue_message(+Type, +Details, -Message) is det.
issue_message(action_conflict, conflict(R1, R2, Subject, Verb, Object, M1, M2), Message) :-
    format(string(Message),
        "Изискванията ~w и ~w си противоречат относно действието \"~w ~w ~w\" (модалност ~w срещу ~w).",
        [R1, R2, Subject, Verb, Object, M1, M2]).

issue_message(numeric_conflict, conflict(R1, R2, Name, Op1, V1, Op2, V2), Message) :-
    format(string(Message),
        "Изискванията ~w и ~w задават несъвместими количествени прагове за \"~w\" (~w ~w срещу ~w ~w).",
        [R1, R2, Name, Op1, V1, Op2, V2]).

issue_message(soft_inconsistency, inconsistency(R1, R2, Name, Op, V1, V2), Message) :-
    format(string(Message),
        "Изискванията ~w и ~w задават различни стойности за \"~w\" (~w ~w срещу ~w ~w) - възможно дублиране или остарял вариант.",
        [R1, R2, Name, Op, V1, Op, V2]).

issue_message(ambiguous, ambiguous(Term), Message) :-
    format(string(Message),
        "Текстът съдържа нееднозначен/неизмерим термин \"~w\", който не може да бъде верифициран еднозначно.",
        [Term]).

issue_message(incomplete, incomplete, Message) :-
    "Изискването няма нито формализирано действие, нито количествен критерий - не може да бъде верифицирано автоматично." = Message.

issue_message(dependency_cycle, cycle(Cycle), Message) :-
    atomic_list_concat(Cycle, ' -> ', CycleStr),
    format(string(Message),
        "Изискването участва в циклична зависимост: ~w.",
        [CycleStr]).

%! issue_suggestion(+Type, +Details, -Suggestion) is det.
issue_suggestion(action_conflict, _, Suggestion) :-
    Suggestion = "Свикайте преглед със заинтересованите страни, за да решите коя модалност е коректна; актуализирайте или отхвърлете едното от двете изисквания.".

issue_suggestion(numeric_conflict, conflict(_, _, Name, _, _, _, _), Suggestion) :-
    format(string(Suggestion),
        "Съгласувайте единен, недвусмислен количествен праг за \"~w\" между всички заинтересовани страни.",
        [Name]).

issue_suggestion(soft_inconsistency, inconsistency(_, _, Name, _, _, _), Suggestion) :-
    format(string(Suggestion),
        "Проверете дали двете изисквания не описват едно и също ограничение за \"~w\"; консолидирайте ги в едно изискване с една стойност.",
        [Name]).

issue_suggestion(ambiguous, ambiguous(Term), Suggestion) :-
    format(string(Suggestion),
        "Заменете термина \"~w\" с измерим критерий (конкретно число, време, процент) и го формализирайте като attribute/5 факт.",
        [Term]).

issue_suggestion(incomplete, _, Suggestion) :-
    Suggestion = "Допълнете изискването с конкретни критерии за приемане (action/5 и/или attribute/5) и ясна дефиниция за завършеност.".

issue_suggestion(dependency_cycle, _, Suggestion) :-
    Suggestion = "Прекъснете цикъла, като премахнете или преформулирате поне една от зависимостите между изброените изисквания.".

% ============================================================
% Генериране на препоръки
% ============================================================

%! recommendation(?Id, ?Type, ?Severity, ?Message, ?Suggestion) is nondet.
recommendation(Id, Type, Severity, Message, Suggestion) :-
    requirement_issue(Id, Type, Details),
    severity(Type, Severity),
    issue_message(Type, Details, Message),
    issue_suggestion(Type, Details, Suggestion).

%! all_recommendations(-Sorted) is det.
%  Списък от rec(Id, Type, Severity, Message, Suggestion),
%  сортиран първо по тежест (critical -> low), после по Id.
all_recommendations(Sorted) :-
    findall(rank(Rank, Id, Type, Severity, Message, Suggestion),
        ( recommendation(Id, Type, Severity, Message, Suggestion),
          severity_rank(Severity, Rank)
        ),
        Ranked),
    sort(1, @=<, Ranked, RankedById0),
    keysort_by_id(RankedById0, RankedById),
    sort(1, @=<, RankedById, FinalSorted0),
    strip_rank(FinalSorted0, Sorted).

% Помощни предикати за стабилно двустепенно сортиране
% (по Rank, после по Id) без зависимост от нестандартни опции.
keysort_by_id(In, Out) :-
    findall(Id-rank(Rank, Id, Type, Severity, Message, Suggestion),
        member(rank(Rank, Id, Type, Severity, Message, Suggestion), In),
        Pairs),
    keysort(Pairs, SortedPairs),
    findall(R, member(_-R, SortedPairs), Out).

strip_rank(In, Out) :-
    findall(rec(Id, Type, Severity, Message, Suggestion),
        member(rank(_, Id, Type, Severity, Message, Suggestion), In),
        Out).

% ============================================================
% Отчет (текстови изход) - използва се от интерфейса в
% Стъпка 5 (interface.pl) и от оценката в Глава 5.
% ============================================================

%! print_recommendations_report is det.
%  Отпечатва форматиран отчет с всички препоръки, групирани по
%  ниво на тежест, плюс обобщена статистика.
print_recommendations_report :-
    all_recommendations(Recs),
    length(Recs, Total),
    format("~n=== ОТЧЕТ ЗА АНАЛИЗ НА ИЗИСКВАНИЯТА ===~n"),
    format("Общ брой открити проблеми: ~w~n~n", [Total]),
    forall(member(rec(Id, Type, Severity, Message, Suggestion), Recs),
        print_single_recommendation(Id, Type, Severity, Message, Suggestion)),
    print_summary(Recs).

print_single_recommendation(Id, Type, Severity, Message, Suggestion) :-
    upcase_atom(Severity, SeverityUp),
    format("[~w] ~w (~w)~n", [SeverityUp, Id, Type]),
    format("  Проблем:    ~w~n", [Message]),
    format("  Препоръка:  ~w~n~n", [Suggestion]).

print_summary(Recs) :-
    format("--- Обобщение по тежест ---~n"),
    forall(member(Sev, [critical, high, medium, low]),
        ( include(has_severity(Sev), Recs, Filtered),
          length(Filtered, N),
          ( N > 0 -> format("  ~w: ~w~n", [Sev, N]) ; true )
        )),
    format("--- Обобщение по тип проблем ---~n"),
    forall(member(Type, [action_conflict, numeric_conflict, soft_inconsistency,
                          ambiguous, incomplete, dependency_cycle]),
        ( include(has_type(Type), Recs, Filtered),
          length(Filtered, N),
          ( N > 0 -> format("  ~w: ~w~n", [Type, N]) ; true )
        )).

has_severity(Sev, rec(_, _, Sev, _, _)).
has_type(Type, rec(_, Type, _, _, _)).
