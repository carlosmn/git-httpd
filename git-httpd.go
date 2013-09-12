package main

import (
	"bytes"
	"fmt"
	"github.com/libgit2/git2go"
	"io"
	"mime"
	"net/http"
	"os"
	"strings"
)

var repo *git.Repository

func handle(w http.ResponseWriter, r *http.Request) {
	// normalize the path
	path := r.URL.Path
	if strings.HasSuffix(path, "/") {
		path = strings.Join([]string{path, "index.html"}, "")
	}

	// grab the tree for the tip of the branch, this is a simple
	// demo, so we use rev-parse. A real program would likely want
	// to do the steps itself
	obj, err := repo.RevparseSingle("refs/heads/gh-pages^{tree}")
	if err != nil {
		fmt.Fprintf(os.Stderr, "fatal: %v\n", err)
		w.WriteHeader(http.StatusNotFound)
		return
	}
	path = path[1:] // remove the leading slash

	tree := obj.(*git.Tree)
	entry, err := tree.EntryByPath(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "fatal: %v\n", err)
		w.WriteHeader(http.StatusNotFound)
		return
	}

	blob, err := repo.LookupBlob(entry.Id)
	if err != nil {
		fmt.Fprintf(os.Stderr, "fatal: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	dot := strings.LastIndex(path, ".")
	header := w.Header()
	header["Content-Type"] = []string{mime.TypeByExtension(path[dot:])}
	io.Copy(w, bytes.NewReader(blob.Contents()))
}

func main() {
	var err error
	repo, err = git.OpenRepository(".")
	if err != nil {
		fmt.Fprintf(os.Stderr, "fatal: %v\n", err)
		return
	}

	http.HandleFunc("/", handle)
	http.ListenAndServe(":8080", nil)
}
