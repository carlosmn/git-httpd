#!/usr/bin/env python

from flask import Flask, abort
import os
import pygit2 as git

REPO_NAME = os.getenv('HOME') + "/git/libgit2/"

app = Flask(__name__)
repo = git.Repository(REPO_NAME)

@app.route('/')
def serve_index():
    return serve('index.html')

@app.route('/<path:filename>')
def serve(filename):
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
