# See LICENSE for licensing information.

PROJECT = cowboy

# Options.

COMPILE_FIRST = 
CT_SUITES = eunit http spdy ws
PLT_APPS = crypto public_key ssl

# Dependencies.

DEPS = meta iso8601 parse_trans jsonrec edown goldrush lager

dep_parse_trans = https://github.com/uwiger/parse_trans.git master
dep_meta = https://github.com/EduardSergeev/meta.git 0.0.2
dep_jsonrec = https://github.com/EduardSergeev/jsonrec.git 0.0.3
dep_iso8601 = https://github.com/seansawyer/erlang_iso8601.git 1.1.1
dep_goldrush = https://github.com/DeadZen/goldrush.git master
dep_lager =	https://github.com/basho/lager.git master
dep_edown = https://github.com/esl/edown master

TEST_DEPS = ct_helper gun
dep_ct_helper = https://github.com/extend/ct_helper.git master
dep_gun = pkg://gun master

# Standard targets.

include erlang.mk

# Extra targets.

.PHONY: autobahn

autobahn: clean clean-deps deps app build-tests
	@mkdir -p logs/
	@$(CT_RUN) -suite autobahn_SUITE
