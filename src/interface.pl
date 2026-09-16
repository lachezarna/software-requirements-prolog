% ============================================================
% interface.pl
% Текстов потребителски интерфейс (CLI) за системата.
% Съответства на т. 4.4 "Потребителски интерфейс и интеграция".
% Позволява преглед на изисквания, стартиране на анализа и
% добавяне на нови изисквания без потребителят да пише
% директно Prolog заявки.
% ============================================================

:- ensure_loaded(kb_schema).
:- ensure_loaded(conflict_rules).
:- ensure_loaded(recommendations).

% ============================================================
% Входна точка
% ============================================================

%! start is det.
start :-
    format("~n"),
    format("============================================~n"),
    format(" Интелигентна система за подпомагане        ~n"),
    format(" управлението на софтуерни изисквания        ~n"),
    format(" (Prolog база от знания)                     ~n"),
    format("============================================~n"),
    main_menu.

main_menu :-
    print_menu,
    read_atom("Избор: ", ChoiceAtom),
    ( ChoiceAtom == '0'
    -> format("~nДовиждане.~n")
    ;  ( catch(handle_choice(ChoiceAtom), Error, report_error(Error))
       -> true
       ;  format("~nНевалиден избор, опитайте отново.~n")
       ),
       nl,
       main_menu
    ).

report_error(Error) :-
    format("~nВъзникна грешка: ~w~n", [Error]).

print_menu :-
    format("~n--- ГЛАВНО МЕНЮ ---~n"),
    format("1. Списък на всички изисквания~n"),
    format("2. Преглед на изискване по Id~n"),
    format("3. Пълен анализ и препоръки~n"),
    format("4. Проблеми за конкретно изискване~n"),
    format("5. Добави ново изискване~n"),
    format("6. Обобщена статистика~n"),
    format("0. Изход~n").

handle_choice('1') :- list_requirements.
handle_choice('2') :-
    read_atom("Id на изискване (напр. req1): ", Id),
    show_requirement(Id).
handle_choice('3') :- print_recommendations_report.
handle_choice('4') :-
    read_atom("Id на изискване (напр. req1): ", Id),
    show_issues_for(Id).
handle_choice('5') :- add_requirement_interactive.
handle_choice('6') :- quick_stats.

% ============================================================
% Опция 1: списък на всички изисквания
% ============================================================

list_requirements :-
    findall(Id, requirement(Id, _, _, _, _, _), Ids0),
    sort(Ids0, Ids),
    length(Ids, N),
    format("~nСПИСЪК НА ИЗИСКВАНИЯТА (~w общо)~n", [N]),
    format("--------------------------------------------~n"),
    forall(member(Id, Ids), print_requirement_line(Id)).

print_requirement_line(Id) :-
    requirement(Id, Type, Text, Priority, Status, Module),
    truncate_text(Text, 60, Short),
    format("~w  [~w/~w/~w/~w]~n    ~w~n", [Id, Type, Priority, Status, Module, Short]).

truncate_text(Text, MaxLen, Short) :-
    string_length(Text, Len),
    ( Len =< MaxLen
    -> Short = Text
    ;  sub_string(Text, 0, MaxLen, _, Prefix),
       string_concat(Prefix, "...", Short)
    ).

% ============================================================
% Опция 2: детайлен преглед на едно изискване
% ============================================================

show_requirement(Id) :-
    ( requirement(Id, Type, Text, Priority, Status, Module)
    -> format("~n=== ~w ===~n", [Id]),
       format("Тип:       ~w~n", [Type]),
       format("Приоритет: ~w~n", [Priority]),
       format("Статус:    ~w~n", [Status]),
       format("Модул:     ~w~n", [Module]),
       format("Текст:     ~w~n", [Text]),
       print_actions(Id),
       print_attributes(Id),
       print_dependencies(Id),
       show_issues_for(Id)
    ;  format("~nИзискване с Id '~w' не съществува.~n", [Id])
    ).

print_actions(Id) :-
    findall(a(S, V, O, M), action(Id, S, V, O, M), Actions),
    ( Actions == []
    -> true
    ;  format("Действия:~n"),
       forall(member(a(S, V, O, M), Actions),
              format("  - ~w ~w ~w  (модалност: ~w)~n", [S, V, O, M]))
    ).

print_attributes(Id) :-
    findall(a(N, Op, V, U), attribute(Id, N, Op, V, U), Attrs),
    ( Attrs == []
    -> true
    ;  format("Атрибути:~n"),
       forall(member(a(N, Op, V, U), Attrs),
              format("  - ~w ~w ~w ~w~n", [N, Op, V, U]))
    ).

print_dependencies(Id) :-
    findall(D, depends_on(Id, D), Deps),
    ( Deps == []
    -> true
    ;  format("Зависи от: ~w~n", [Deps])
    ).

% ============================================================
% Опции 3/4: анализ и проблеми за конкретно изискване
% ============================================================

show_issues_for(Id) :-
    ( requirement(Id, _, _, _, _, _)
    -> findall(rec(Id, Type, Sev, Msg, Sugg),
               recommendation(Id, Type, Sev, Msg, Sugg),
               Recs),
       ( Recs == []
       -> format("~nПроблеми: не са открити проблеми за ~w.~n", [Id])
       ;  length(Recs, N),
          format("~nОткрити проблеми за ~w (~w):~n", [Id, N]),
          forall(member(rec(_, Type, Sev, Msg, Sugg), Recs),
                 ( upcase_atom(Sev, SevUp),
                   format("  [~w] (~w)~n", [SevUp, Type]),
                   format("    Проблем:   ~w~n", [Msg]),
                   format("    Препоръка: ~w~n", [Sugg])
                 ))
       )
    ;  format("~nИзискване с Id '~w' не съществува.~n", [Id])
    ).

% ============================================================
% Опция 5: интерактивно добавяне на ново изискване
% ============================================================

add_requirement_interactive :-
    read_atom("Нов Id (напр. req15): ", Id),
    ( requirement(Id, _, _, _, _, _)
    -> format("~nИзискване с Id '~w' вече съществува.~n", [Id])
    ;  read_atom("Тип (functional/nonfunctional): ", Type),
       read_text("Текст на изискването: ", Text),
       read_atom("Приоритет (low/medium/high/critical): ", Priority),
       read_atom("Статус (draft/reviewed/approved/rejected): ", Status),
       read_atom("Модул: ", Module),
       assertz(requirement(Id, Type, Text, Priority, Status, Module)),
       format("~nИзискване ~w беше добавено успешно.~n", [Id]),
       maybe_add_action(Id),
       maybe_add_attribute(Id),
       format("~n--- Анализ на новото изискване ---"),
       show_issues_for(Id)
    ).

maybe_add_action(Id) :-
    read_atom("Добавяне на действие (action) към изискването? (y/n): ", Ans),
    ( Ans == y
    -> read_atom("  Subject (напр. system): ", S),
       read_atom("  Verb (напр. allow): ", V),
       read_atom("  Object (напр. guest_checkout): ", O),
       read_atom("  Modality (must/must_not/should/should_not/may): ", M),
       assertz(action(Id, S, V, O, M)),
       format("  Действие добавено.~n")
    ;  true
    ).

maybe_add_attribute(Id) :-
    read_atom("Добавяне на количествен атрибут (attribute) към изискването? (y/n): ", Ans),
    ( Ans == y
    -> read_atom("  Име (напр. response_time): ", N),
       read_atom("  Оператор (eq/lt/lte/gt/gte): ", Op),
       read_atom("  Стойност (число): ", ValAtom),
       atom_number(ValAtom, Val),
       read_atom("  Мерна единица (напр. seconds, chars; none ако няма): ", U),
       assertz(attribute(Id, N, Op, Val, U)),
       format("  Атрибут добавен.~n")
    ;  true
    ).

% ============================================================
% Опция 6: обобщена статистика
% ============================================================

quick_stats :-
    findall(Id, requirement(Id, _, _, _, _, _), Reqs),
    length(Reqs, NReqs),
    all_recommendations(Recs),
    length(Recs, NIssues),
    format("~nОбщо изисквания в базата: ~w~n", [NReqs]),
    format("Общо открити проблеми:    ~w~n", [NIssues]),
    print_summary(Recs).

% ============================================================
% Помощни предикати за въвеждане от потребителя
% ============================================================

%! read_atom(+Prompt, -Atom) is det.
read_atom(Prompt, Atom) :-
    format("~w", [Prompt]),
    flush_output,
    read_line_to_string(user_input, Str),
    ( Str == end_of_file -> halt ; true ),
    normalize_space(atom(Atom), Str).

%! read_text(+Prompt, -Text) is det.
%  Като read_atom/2, но резултатът е string (за свободен текст).
read_text(Prompt, Text) :-
    format("~w", [Prompt]),
    flush_output,
    read_line_to_string(user_input, Str),
    ( Str == end_of_file -> halt ; true ),
    normalize_space(string(Text), Str).
