#!/bin/sh

GEEF_PATH=$HOME/git/geef
COWBOY_PATH=cowboy
MIMETYPES_PATH=mimetypes

export GIT_HTTPD_ROOT=$HOME/git/libgit2

elixir -pa "$GEEF_PATH/ebin" -pa "$COWBOY_PATH/ebin" -pa $COWBOY_PATH/'deps/*/ebin' -pa "$MIMETYPES_PATH/ebin" git_httpd.exs
