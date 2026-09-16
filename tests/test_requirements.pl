% ============================================================
% test_requirements.pl
% Автоматизиран тестов набор (plunit) върху примерните
% изисквания от src/requirements_data.pl. Съответства на т. 5.2
% "Тестов набор от изисквания и сценарии за откриване на
% противоречия" - служи и като регресионен тест, доказващ
% коректността на правилата от Глава 3/4.2.
% ============================================================

:- set_prolog_flag(encoding, utf8).

:- ensure_loaded('../src/kb_schema').
:- ensure_loaded('../src/requirements_data').
:- ensure_loaded('../src/conflict_rules').
:- ensure_loaded('../src/recommendations').

:- use_module(library(plunit)).

% ------------------------------------------------------------
% Цялост на данните (sanity checks върху тестовия набор)
% ------------------------------------------------------------
:- begin_tests(data_integrity).

test(unique_ids) :-
    findall(Id, requirement(Id, _, _, _, _, _), Ids),
    sort(Ids, Sorted),
    length(Ids, N),
    length(Sorted, N).

test(valid_types) :-
    forall(requirement(_, Type, _, _, _, _),
           memberchk(Type, [functional, nonfunctional])).

test(valid_priorities) :-
    forall(requirement(_, _, _, Priority, _, _),
           memberchk(Priority, [low, medium, high, critical])).

test(valid_statuses) :-
    forall(requirement(_, _, _, _, Status, _),
           memberchk(Status, [draft, reviewed, approved, rejected])).

:- end_tests(data_integrity).

% ------------------------------------------------------------
% 1. Пряко логическо противоречие (action_conflict)
% ------------------------------------------------------------
:- begin_tests(action_conflicts).

test(req1_req2_detected) :-
    action_conflict(req1, req2, system, allow, guest_checkout, must, must_not).

test(no_false_positive_req3) :-
    \+ action_conflict(req3, _, _, _, _, _, _),
    \+ action_conflict(_, req3, _, _, _, _, _).

test(no_false_positive_req7) :-
    \+ action_conflict(req7, _, _, _, _, _, _),
    \+ action_conflict(_, req7, _, _, _, _, _).

:- end_tests(action_conflicts).

% ------------------------------------------------------------
% 2. Числово противоречие (numeric_conflict)
% ------------------------------------------------------------
:- begin_tests(numeric_conflicts).

test(req5_req6_detected) :-
    numeric_conflict(req5, req6, response_time, lte, 2, gte, 5).

test(req8_req9_not_a_hard_conflict) :-
    \+ numeric_conflict(req8, req9, password_length, gte, 8, gte, 4).

test(compatible_ranges_not_flagged) :-
    \+ numeric_ranges_disjoint(lte, 5, gte, 2).

test(incompatible_ranges_flagged) :-
    numeric_ranges_disjoint(lte, 2, gte, 5).

:- end_tests(numeric_conflicts).

% ------------------------------------------------------------
% 3. "Мека" несъгласуваност (soft_inconsistency)
% ------------------------------------------------------------
:- begin_tests(soft_inconsistencies).

test(req8_req9_detected) :-
    soft_inconsistency(req8, req9, password_length, gte, 8, 4).

test(hard_conflict_not_also_soft) :-
    \+ soft_inconsistency(req5, req6, response_time, _, _, _).

:- end_tests(soft_inconsistencies).

% ------------------------------------------------------------
% 4. Нееднозначност (ambiguous_requirement)
% ------------------------------------------------------------
:- begin_tests(ambiguous).

test(req4_flagged) :-
    once(ambiguous_requirement(req4, _)).

test(req12_flagged) :-
    once(ambiguous_requirement(req12, _)).

test(req7_not_flagged) :-
    \+ ambiguous_requirement(req7, _).

test(req5_not_flagged_because_measurable) :-
    % req5 съдържа число/измерим attribute, не трябва да е "нееднозначно"
    \+ ambiguous_requirement(req5, _).

:- end_tests(ambiguous).

% ------------------------------------------------------------
% 5. Непълнота (incomplete_requirement)
% ------------------------------------------------------------
:- begin_tests(incomplete).

test(req10_flagged) :-
    once(incomplete_requirement(req10)).

test(req1_not_flagged_has_action) :-
    \+ incomplete_requirement(req1).

test(req5_not_flagged_has_attribute) :-
    \+ incomplete_requirement(req5).

:- end_tests(incomplete).

% ------------------------------------------------------------
% 6. Циклична зависимост (dependency_cycle)
% ------------------------------------------------------------
:- begin_tests(dependency_cycles).

test(single_cycle_found) :-
    all_dependency_cycles(Cycles),
    length(Cycles, 1).

test(cycle_contains_req13_and_req14) :-
    all_dependency_cycles([Cycle]),
    list_to_set(Cycle, Set),
    sort(Set, [req13, req14]).

test(req11_dependencies_not_cyclic) :-
    \+ dependency_cycle(req11, _).

:- end_tests(dependency_cycles).

% ------------------------------------------------------------
% 7. Обобщени препоръки - брой и разпределение по тежест
% ------------------------------------------------------------
:- begin_tests(recommendations).

test(total_issue_count) :-
    all_recommendations(Recs),
    length(Recs, 17).

test(critical_count) :-
    all_recommendations(Recs),
    include(has_severity(critical), Recs, Critical),
    length(Critical, 6).

test(medium_count) :-
    all_recommendations(Recs),
    include(has_severity(medium), Recs, Medium),
    length(Medium, 6).

test(low_count) :-
    all_recommendations(Recs),
    include(has_severity(low), Recs, Low),
    length(Low, 5).

test(sorted_by_severity_first) :-
    all_recommendations([rec(_, _, FirstSeverity, _, _) | _]),
    FirstSeverity == critical.

test(report_generation_does_not_error) :-
    with_output_to(string(_), print_recommendations_report).

:- end_tests(recommendations).
