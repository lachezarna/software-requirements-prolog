% ============================================================
% conflict_rules.pl
% Правила за автоматизиран анализ на изисквания: откриване на
% противоречия и проблеми. Съответства на:
%   - Глава 3 "Методи за анализ на изисквания, откриване на
%     противоречия и проблеми" (3.1, 3.2)
%   - т. 4.2 "Формализация на правила за откриване на
%     противоречия и проблеми"
% ============================================================

:- ensure_loaded(kb_schema).

% ============================================================
% 1. ПРЯКО ЛОГИЧЕСКО ПРОТИВОРЕЧИЕ (деонтична несъвместимост)
%    Две различни изисквания твърдят несъвместими модалности
%    за едно и също действие (Subject, Verb, Object).
% ============================================================

% Двойки несъвместими модалности (деонтична логика)
incompatible_modality(must, must_not).
incompatible_modality(must_not, must).
incompatible_modality(should, should_not).
incompatible_modality(should_not, should).
incompatible_modality(must, should_not).
incompatible_modality(should_not, must).
incompatible_modality(must_not, should).
incompatible_modality(should, must_not).

%! action_conflict(?R1, ?R2, ?Subject, ?Verb, ?Object, ?M1, ?M2) is nondet.
%  Двете изисквания R1 и R2 (R1 @< R2, за да няма дублиране на
%  резултата AB/BA) описват едно и също действие с несъвместими
%  модалности.
action_conflict(R1, R2, Subject, Verb, Object, M1, M2) :-
    action(R1, Subject, Verb, Object, M1),
    action(R2, Subject, Verb, Object, M2),
    R1 @< R2,
    incompatible_modality(M1, M2).

% ============================================================
% 2. ЧИСЛОВО (КОЛИЧЕСТВЕНО) ПРОТИВОРЕЧИЕ
%    Две изисквания задават несъвместими количествени
%    ограничения за един и същ измерим атрибут (напр. едно
%    изисква response_time <= 2s, друго - response_time >= 5s).
% ============================================================

%! numeric_conflict(?R1, ?R2, ?Name, ?Op1, ?V1, ?Op2, ?V2) is nondet.
numeric_conflict(R1, R2, Name, Op1, V1, Op2, V2) :-
    attribute(R1, Name, Op1, V1, _Unit1),
    attribute(R2, Name, Op2, V2, _Unit2),
    R1 @< R2,
    numeric_ranges_disjoint(Op1, V1, Op2, V2).

% Диапазоните, зададени от двете ограничения, са несъвместими
% (не съществува число, удовлетворяващо и двете едновременно).
numeric_ranges_disjoint(Op1, V1, Op2, V2) :-
    upper_bound(Op1, V1, U), lower_bound(Op2, V2, L), L > U, !.
numeric_ranges_disjoint(Op1, V1, Op2, V2) :-
    upper_bound(Op2, V2, U), lower_bound(Op1, V1, L), L > U, !.
numeric_ranges_disjoint(eq, V1, Op2, V2) :-
    \+ satisfies(Op2, V2, V1), !.
numeric_ranges_disjoint(Op1, V1, eq, V2) :-
    \+ satisfies(Op1, V1, V2), !.

upper_bound(lt, V, V).
upper_bound(lte, V, V).
upper_bound(eq, V, V).
lower_bound(gt, V, V).
lower_bound(gte, V, V).
lower_bound(eq, V, V).

satisfies(eq,  V, X) :- X =:= V.
satisfies(lt,  V, X) :- X <  V.
satisfies(lte, V, X) :- X =< V.
satisfies(gt,  V, X) :- X >  V.
satisfies(gte, V, X) :- X >= V.

% ============================================================
% 3. "МЕКА" НЕСЪГЛАСУВАНОСТ
%    Два прага за един и същ атрибут и оператор не са логически
%    противоречиви, но разликата им е признак за неконсистентно
%    (вероятно дублирано/остаряло) изискване, което трябва да
%    бъде прегледано ръчно.
% ============================================================

%! soft_inconsistency(?R1, ?R2, ?Name, ?Op, ?V1, ?V2) is nondet.
soft_inconsistency(R1, R2, Name, Op, V1, V2) :-
    attribute(R1, Name, Op, V1, _),
    attribute(R2, Name, Op, V2, _),
    R1 @< R2,
    V1 =\= V2,
    \+ numeric_conflict(R1, R2, Name, Op, V1, Op, V2).

% ============================================================
% 4. НЕЕДНОЗНАЧНОСТ (АМБИГУИТЕТ)
%    Текстът на изискването съдържа субективни/неизмерими
%    термини, които не могат да бъдат верифицирани еднозначно.
%    (виж 3.3 "NLP техники за откриване на нееднозначност")
% ============================================================

ambiguous_term("бърз").
ambiguous_term("бърза").
ambiguous_term("бързо").
ambiguous_term("удобен").
ambiguous_term("удобно").
ambiguous_term("лесен").
ambiguous_term("лесно").
ambiguous_term("интуитивен").
ambiguous_term("интуитивно").
ambiguous_term("ефективен").
ambiguous_term("ефективно").
ambiguous_term("достатъчно").
ambiguous_term("подходящ").
ambiguous_term("подходящо").
ambiguous_term("гъвкав").
ambiguous_term("гъвкаво").
ambiguous_term("сигурен").
ambiguous_term("сигурно").
ambiguous_term("бързодействащ").
ambiguous_term("удобен за употреба").

%! ambiguous_requirement(?Id, ?Term) is nondet.
%  Изискването с Id съдържа нееднозначен/неизмерим термин Term
%  в текста си и НЕ е подкрепено от количествен атрибут
%  (attribute/5), който да го прави проверимо.
ambiguous_requirement(Id, Term) :-
    requirement(Id, _, Text, _, _, _),
    ambiguous_term(Term),
    sub_string_ci(Text, Term),
    \+ attribute(Id, _, _, _, _).

% Проверка за подниз без чувствителност към главни/малки букви.
sub_string_ci(Text, Sub) :-
    string_lower(Text, TextLower),
    string_lower(Sub, SubLower),
    sub_string(TextLower, _, _, _, SubLower).

% ============================================================
% 5. НЕПЪЛНОТА
%    Функционално изискване няма нито описание на действие
%    (action/5), нито количествен критерий (attribute/5) -
%    липсват достатъчно данни, за да бъде верифицирано.
% ============================================================

%! incomplete_requirement(?Id) is nondet.
incomplete_requirement(Id) :-
    requirement(Id, Type, _Text, _, _, _),
    \+ action(Id, _, _, _, _),
    \+ attribute(Id, _, _, _, _),
    ( Type == functional
    ; Type == nonfunctional
    ).

% ============================================================
% 6. ЦИКЛИЧНА ЗАВИСИМОСТ
%    Верига от зависимости depends_on/2, която се връща към
%    началното изискване - прави изискванията невъзможни за
%    едновременно удовлетворяване в реда, зададен от плана.
% ============================================================

%! dependency_cycle(?Id, ?Cycle) is nondet.
%  Cycle е списък от идентификатори, представляващ цикъла,
%  започващ и завършващ в Id.
dependency_cycle(Id, Cycle) :-
    requirement(Id, _, _, _, _, _),
    dependency_path(Id, Id, [Id], RevCycle),
    reverse(RevCycle, Cycle).

dependency_path(Start, Current, Acc, Cycle) :-
    depends_on(Current, Next),
    ( Next == Start
    -> Cycle = [Start | Acc]
    ;  \+ member(Next, Acc),
       dependency_path(Start, Next, [Next | Acc], Cycle)
    ).

%! all_dependency_cycles(-Cycles) is det.
%  Уникален списък от намерените цикли (без дублиране на един и
%  същ цикъл, стартиран от различни негови елементи).
all_dependency_cycles(Cycles) :-
    findall(Cycle, dependency_cycle(_, Cycle), All),
    normalize_and_dedupe_cycles(All, Cycles).

normalize_and_dedupe_cycles(All, Cycles) :-
    findall(NormSet-Cycle, (member(Cycle, All), cycle_key(Cycle, NormSet)), Pairs),
    dedupe_by_key(Pairs, [], Cycles).

% Ключ на цикъл = сортирано множество от участващите Id-та, без
% повтарящия се начален/краен елемент - служи за детекция на
% дублиращи се цикли, докладвани от различни стартови точки.
cycle_key(Cycle, SortedSet) :-
    list_to_set(Cycle, SetList),
    sort(SetList, SortedSet).

dedupe_by_key([], _, []).
dedupe_by_key([Key-Cycle | Rest], Seen, [Cycle | Out]) :-
    \+ member(Key, Seen), !,
    dedupe_by_key(Rest, [Key | Seen], Out).
dedupe_by_key([_-_ | Rest], Seen, Out) :-
    dedupe_by_key(Rest, Seen, Out).

% ============================================================
% 7. ОБОБЩАВАЩО ПРАВИЛО: ВСИЧКИ ПРОБЛЕМИ ПРИ ЕДНО ИЗИСКВАНЕ
% ============================================================

%! requirement_issue(?Id, ?IssueType, ?Details) is nondet.
%  Единна точка на достъп до всички видове проблеми, открити за
%  изискване Id. IssueType е един от:
%    action_conflict, numeric_conflict, soft_inconsistency,
%    ambiguous, incomplete, dependency_cycle
requirement_issue(R1, action_conflict, conflict(R1, R2, Subject, Verb, Object, M1, M2)) :-
    action_conflict(R1, R2, Subject, Verb, Object, M1, M2).
requirement_issue(R2, action_conflict, conflict(R1, R2, Subject, Verb, Object, M1, M2)) :-
    action_conflict(R1, R2, Subject, Verb, Object, M1, M2).

requirement_issue(R1, numeric_conflict, conflict(R1, R2, Name, Op1, V1, Op2, V2)) :-
    numeric_conflict(R1, R2, Name, Op1, V1, Op2, V2).
requirement_issue(R2, numeric_conflict, conflict(R1, R2, Name, Op1, V1, Op2, V2)) :-
    numeric_conflict(R1, R2, Name, Op1, V1, Op2, V2).

requirement_issue(R1, soft_inconsistency, inconsistency(R1, R2, Name, Op, V1, V2)) :-
    soft_inconsistency(R1, R2, Name, Op, V1, V2).
requirement_issue(R2, soft_inconsistency, inconsistency(R1, R2, Name, Op, V1, V2)) :-
    soft_inconsistency(R1, R2, Name, Op, V1, V2).

requirement_issue(Id, ambiguous, ambiguous(Term)) :-
    ambiguous_requirement(Id, Term).

requirement_issue(Id, incomplete, incomplete) :-
    incomplete_requirement(Id).

requirement_issue(Id, dependency_cycle, cycle(Cycle)) :-
    all_dependency_cycles(Cycles),
    member(Cycle, Cycles),
    list_to_set(Cycle, UniqueIds),
    member(Id, UniqueIds).

%! all_issues(-Issues) is det.
%  Issues е списък от issue(Id, IssueType, Details) за всички
%  открити проблеми в текущата база от знания.
all_issues(Issues) :-
    findall(issue(Id, Type, Details), requirement_issue(Id, Type, Details), Issues).
