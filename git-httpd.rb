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

  entry = commit.tree.path path
  puts path
  blob = repo.lookup entry[:oid]
  content = blob.content
  halt 404, "404 Not Found" unless content

  content_type MIME::Types.type_for(path).first.content_type
  content
end
