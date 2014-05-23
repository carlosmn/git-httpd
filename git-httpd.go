package main

import (
	"errors"
	"flag"
	"github.com/libgit2/git2go"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

type GitFile struct {
	entry  *git.TreeEntry
	blob   *git.Blob
	offset int64
}

type GitFileInfo struct {
	entry *git.TreeEntry
	obj   git.Object
}

func (v *GitFile) Close() error {
	v.blob.Free()
	v.blob = nil

	return nil
}

func (v *GitFile) Read(out []byte) (int, error) {
	data := v.blob.Contents()

	n := copy(out, data[v.offset:])
	v.offset += int64(n)

	return n, nil
}

func (v *GitFile) Readdir(count int) ([]os.FileInfo, error) {
	return nil, errors.New("I'm not a directory")
}

func (v *GitFile) Seek(offset int64, whence int) (int64, error) {
	// whence values as raw ints, programming like it's 1990
	switch whence {
	case 0:
		v.offset = offset
	case 1:
		v.offset += offset
	case 2:
		v.offset = v.blob.Size() + offset
	default:
		return 0, errors.New("invalid whence")
	}

	return v.offset, nil
}

func (v *GitFile) Stat() (os.FileInfo, error) {
	return &GitFileInfo{
		entry: v.entry,
		obj:   v.blob,
	}, nil
}

func (v *GitFileInfo) Name() string {
	return v.entry.Name
}

func (v *GitFileInfo) Size() int64 {
	// the real size for a "file", otherwise whatever
	if blob, ok := v.obj.(*git.Blob); ok {
		return blob.Size()
	}

	return 0
}

func (v *GitFileInfo) Mode() os.FileMode {
	var mode os.FileMode

	switch v.entry.Filemode {
	case git.FilemodeBlob:
		mode = 0
	case git.FilemodeTree:
		mode = os.ModeDir
	}

	return mode
}

func (v *GitFileInfo) ModTime() time.Time {
	return time.Now()
}

func (v *GitFileInfo) IsDir() bool {
	return v.Mode().IsDir()
}

func (v *GitFileInfo) Sys() interface{} {
	return nil
}

type GitTree struct {
	entry *git.TreeEntry
	tree  *git.Tree
}

func (v *GitTree) Close() error {
	v.tree.Free()
	v.tree = nil

	return nil
}

func (v *GitTree) Read(out []byte) (int, error) {
	return 0, io.EOF
}

func (v *GitTree) Readdir(count int) ([]os.FileInfo, error) {
	return nil, errors.New("not implemented yet")
}

func (v *GitTree) Seek(offset int64, whence int) (int64, error) {
	return 0, errors.New("what you wanna seek")
}

func (v *GitTree) Stat() (os.FileInfo, error) {
	return &GitFileInfo{
		entry: v.entry,
		obj:   v.tree,
	}, nil
}

type GitFileSystem struct {
	repo *git.Repository
	tree *git.Tree
}

func (v *GitFileSystem) Open(name string) (http.File, error) {
	var err error
	var entry *git.TreeEntry

	if name == "/" {
		entry = &git.TreeEntry{
			Name:     "",
			Type:     git.ObjectTree,
			Filemode: git.FilemodeTree,
			Id:       v.tree.Id(),
		}
	} else {
		// for some reason we're asked for //index.html
		for strings.HasPrefix(name, "/") {
			name = name[1:]
		}
		if entry, err = v.tree.EntryByPath(name); err != nil {
			return nil, err
		}
	}

	if entry.Type == git.ObjectTree {
		var tree *git.Tree

		if tree, err = v.repo.LookupTree(entry.Id); err != nil {
			return nil, err
		}

		return &GitTree{
			entry: entry,
			tree:  tree,
		}, nil
	}

	var blob *git.Blob
	if blob, err = v.repo.LookupBlob(entry.Id); err != nil {
		return nil, err
	}

	return &GitFile{
		entry: entry,
		blob:  blob,
	}, nil
}

func NewGitFileSystemFromBranch(repo *git.Repository, branch string) (http.FileSystem, error) {
	var ref *git.Reference
	var obj git.Object
	var err error

	if ref, err = repo.LookupReference(branch); err != nil {
		return nil, err
	}

	if obj, err = ref.Peel(git.ObjectTree); err != nil {
		return nil, err
	}

	return &GitFileSystem{
		repo: repo,
		tree: obj.(*git.Tree),
	}, nil
}

func main() {
	var repoName, refName string

	flag.StringVar(&repoName, "repo", ".", "repository path")
	flag.StringVar(&refName, "ref", "refs/heads/gh-pages", "reference to serve")
	flag.Parse();

	var err error
	repo, err := git.OpenRepository(repoName)
	if err != nil {
		log.Fatal(err)
		return
	}

	fs, err := NewGitFileSystemFromBranch(repo, refName)
	if err != nil {
		log.Fatal(err)
		return
	}

	log.Fatal(http.ListenAndServe(":8080", http.FileServer(fs)))
}
