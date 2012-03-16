#!/usr/bin/env python

from flask import Flask, render_template, url_for, abort
import os, os.path, md5
import pygit2 as git
from time import gmtime, strftime
from urllib import urlencode

REPO_NAME = os.getenv('HOME') + "/git/libgit2/"

app = Flask(__name__)

@app.route('/')
def serve_index():
    return serve('index.html')

@app.route('/<path:filename>')
def serve(filename):
    print("opening " + REPO_NAME)
    repo = git.Repository(REPO_NAME)
    oid = repo.lookup_reference('refs/heads/gh-pages').resolve().oid
    tree = repo[oid].tree
    parts = filename.split('/')
    while len(parts) > 1:
            dirname = parts.pop(0)
            print("dirname " + dirname)
            tree = tree[dirname].to_object()

    last = parts.pop(0)
    if last == '':
        last = 'index.html'

    try:
        return tree[last].to_object().data
    except KeyError:
        abort(404)

if __name__ == "__main__":
    app.debug = True
    app.run()
