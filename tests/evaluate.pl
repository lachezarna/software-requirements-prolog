% ============================================================
% evaluate.pl
% Стартира оценката на резултатите (т. 5.3).
%
% Стартиране:
%   swipl tests/evaluate.pl
% ============================================================

:- set_prolog_flag(encoding, utf8).
:- set_stream(user_output, encoding(utf8)).
:- set_stream(user_error, encoding(utf8)).

:- ensure_loaded('../src/evaluation').

:- initialization(main, main).

main :-
    print_evaluation_report,
    halt(0).
