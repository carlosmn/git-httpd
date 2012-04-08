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
  if path.empty?
    path = 'index.html'
  end
  puts path
  content = repo.file_at(commit.oid, path)
  if content.nil?
    halt 404, "404 Not Found"
  end

  content_type MIME::Types.type_for(path).first.content_type
  # tree is now the last object (could do with better naming)
  content
end
