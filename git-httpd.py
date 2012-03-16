#!/usr/bin/env python

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import os
import pygit2 as git

REPO_NAME = os.getenv('HOME') + "/git/libgit2/"
REF_NAME = 'refs/heads/gh-pages'
repo = git.Repository(REPO_NAME)

class git_httpd(BaseHTTPRequestHandler):
    def guess_type(self, filename):
        if filename.endswith('.html') or filename.endswith('.htm'):
            return "text/html"
        elif filename.endswith('.css'):
            return 'text/css'
        elif filename.endswith('.js'):
            return 'application/javascript'
        else:
            return 'application/octet-stream'

    def not_found(self):
        self.send_response(404)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        o = self.wfile
        o.write('404 File Not Found')

    def send_blob(self, filename, object):
        self.send_response(200)
        self.send_header('Content-Type', self.guess_type(filename))
        self.end_headers()
        o = self.wfile
        o.write(object.data)

    def do_GET(self):
        if self.path == '/':
            self.path = 'index.html'

        oid = repo.lookup_reference(REF_NAME).resolve().oid
        tree = repo[oid].tree
        parts = self.path.rsplit('/')
        print parts
        try:
            while len(parts) > 1:
                dirname = parts.pop(0)
                # /one/two is ['', 'one', 'two']
                if dirname == '':
                    continue

                tree = tree[dirname].to_object()
        except KeyError:
            return self.not_found()

        last = parts.pop(0)
        if last == '':
            last = 'index.html'

        try:
            return self.send_blob(last, tree[last].to_object())
        except KeyError:
            return self.not_found()

try:
    server = HTTPServer(('', 8080), git_httpd)
    server.serve_forever()
except KeyboardInterrupt:
    server.socket.close()
