#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'rugged'
require 'mime/types'

REPO_PATH = ENV['HOME'] + '/git/libgit2'
REF_NAME = 'refs/heads/gh-pages'

repo = Rugged::Repository.new(REPO_PATH)

get '*' do |path|
  ref = Rugged::Reference.lookup(repo, REF_NAME)
  commit = repo.lookup(ref.target)
  tree = repo.lookup(commit.tree.oid)
  parts = path.split('/').reject! { |str| str.empty? }

  parts = parts.nil? ? ['index.html'] : parts

  parts.each { |n|
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
