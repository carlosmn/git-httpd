package main

import (
	"flag"
	"github.com/carlosmn/go.gitfs"
	"github.com/libgit2/git2go"
	"log"
	"net/http"
)

func main() {
	var repoName, refName string

	flag.StringVar(&repoName, "repo", ".", "repository path")
	flag.StringVar(&refName, "ref", "refs/heads/gh-pages", "reference to serve")
	flag.Parse()

	var err error
	repo, err := git.OpenRepository(repoName)
	if err != nil {
		log.Fatal(err)
		return
	}

	fs, err := gitfs.NewFromReferenceName(repo, refName)
	if err != nil {
		log.Fatal(err)
		return
	}

	log.Fatal(http.ListenAndServe(":8080", http.FileServer(fs)))
}
