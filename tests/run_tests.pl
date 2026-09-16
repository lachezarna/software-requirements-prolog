% ============================================================
% run_tests.pl
% Стартира целия тестов набор и излиза с код 0 при успех,
% 1 при провален тест - подходящо за CI/автоматизация.
%
% Стартиране:
%   swipl tests/run_tests.pl
% ============================================================

:- set_prolog_flag(encoding, utf8).
:- set_stream(user_output, encoding(utf8)).
:- set_stream(user_error, encoding(utf8)).

:- ensure_loaded('test_requirements').

:- initialization(main, main).

main :-
    ( run_tests
    -> format("~nALL TESTS PASSED.~n"),
       halt(0)
    ;  format("~nSOME TESTS FAILED.~n"),
       halt(1)
    ).
