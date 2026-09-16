% ============================================================
% main.pl
% Главен входен файл на "Интелигентна система за подпомагане
% управлението на софтуерни изисквания чрез Prolog".
%
% Стартиране:
%   swipl main.pl
% ============================================================

:- set_prolog_flag(encoding, utf8).
:- set_stream(user_input, encoding(utf8)).
:- set_stream(user_output, encoding(utf8)).
:- set_stream(user_error, encoding(utf8)).

:- ensure_loaded('src/kb_schema').
:- ensure_loaded('src/requirements_data').
:- ensure_loaded('src/conflict_rules').
:- ensure_loaded('src/recommendations').
:- ensure_loaded('src/interface').

:- initialization(start, main).
