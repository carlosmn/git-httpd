#!/usr/bin/env python

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import mimetypes
import os
import pygit2 as git

REPO_NAME = os.getenv('HOME') + "/git/libgit2/"
REF_NAME = 'refs/heads/gh-pages'

repo = git.Repository(REPO_NAME)
mimetypes.init()

class git_httpd(BaseHTTPRequestHandler):
    def not_found(self):
        self.send_response(404)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        o = self.wfile
        o.write('404 File Not Found')

    def send_blob(self, entry):
        (type, encoding) = mimetypes.guess_type(entry.name)
        self.send_response(200)
        self.send_header('Content-Type', type)
        self.end_headers()
        o = self.wfile
        o.write(entry.to_object().data)

    def do_GET(self):
        if self.path == '/':
            self.path = 'index.html'

        oid = repo.lookup_reference(REF_NAME).resolve().oid
        tree = repo[oid].tree
        parts = self.path.rsplit('/')
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
            return self.send_blob(tree[last])
        except KeyError:
            return self.not_found()

try:
    server = HTTPServer(('', 8080), git_httpd)
    server.serve_forever()
except KeyboardInterrupt:
    server.socket.close()
