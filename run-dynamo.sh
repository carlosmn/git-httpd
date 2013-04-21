#!/bin/sh

DYNAMO_PATH=$HOME/apps/dynamo
GEEF_PATH=$HOME/git/geef

export GIT_HTTPD_ROOT=$HOME/git/libgit2

elixir -pa "$GEEF_PATH/ebin" -pa "$DYNAMO_PATH/ebin" -pa "$DYNAMO_PATH/deps/*/ebin" git_httpd.exs
#elixir -pa ~/git/geef/ebin -pa ebin -pa 'deps/*/ebin' ~/git/git-httpd/git_httpd.exs
