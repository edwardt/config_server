# See LICENSE for licensing information.

PROJECT = cowboy

# Options.

COMPILE_FIRST = cowboy_middleware cowboy_sub_protocol
CT_SUITES = eunit http spdy ws
PLT_APPS = crypto public_key ssl

# Dependencies.

DEPS = cowlib ranch parse_trans json_rec edown goldrush lager
dep_cowlib = pkg://cowlib 0.1.0
dep_ranch = pkg://ranch 0.8.5
dep_parse_trans = https://github.com/uwiger/parse_trans.git 
dep_json_rec = https://github.com/justinkirby/json_rec.git  
dep_edown = https://github.com/esl/edown.git 
#dep_exmpp = https://github.com/processone/exmpp.git v0.9.9
dep_goldrush = https://github.com/DeadZen/goldrush.git
dep_lager = https://github.com/basho/lager.git 

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
