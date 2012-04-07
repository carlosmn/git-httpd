#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'rugged'
require 'mime/types'

repo = Rugged::Repository.new('/home/carlos/git/libgit2')

get '*' do |path|
  parts = path.split('/')[1:]
  ref = Rugged::Reference.lookup(repo, 'refs/heads/gh-pages')
  commit = repo.lookup(ref.target)
  tree = repo.lookup(commit.tree.oid)

  if parts.empty? then parts = ['index.html'] end

  puts parts.inspect
  parts.each { |n|
    if n == "" then next end
    entry = tree[n]
    if entry == nil
      halt 404, ""
    end
    tree = repo.lookup(entry[:oid])
  }

  content_type MIME::Types.type_for(parts.last).first.content_type
  # tree is now the last object (could do with better naming)
  tree.content
end
