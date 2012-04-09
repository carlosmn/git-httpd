#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'rugged'
require 'mime/types'

REPO_PATH = ENV['HOME'] + '/git/libgit2'
REF_NAME = 'refs/heads/gh-pages'

repo = Rugged::Repository.new(REPO_PATH)

get '*' do |path|
  commit = repo.lookup(repo.ref(REF_NAME).target)
  path.slice!(0)
  path = 'index.html' if path.empty?

  puts path
  content = repo.file_at(commit.oid, path)
  halt 404, "404 Not Found" unless content

  content_type MIME::Types.type_for(path).first.content_type
  content
end
