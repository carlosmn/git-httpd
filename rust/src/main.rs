extern crate hyper;
extern crate git2;

use std::path::Path;
use std::io::Write;

use hyper::Server;
use hyper::server::{Request, Response};
use hyper::status::StatusCode;
use hyper::net::Fresh;
use hyper::uri::RequestUri;

use git2::{Repository};
use git2::Error;

fn internal_error(mut res: Response<Fresh>, err: Error) {
    *res.status_mut() = StatusCode::InternalServerError;
    res.send(err.message().as_bytes()).unwrap();
}

fn main() {
    let path = if let Some(ppath) = std::env::args().nth(1) {
        ppath
    } else {
        std::io::stderr().write("usage: git-httpd <repo path>\n".as_bytes()).unwrap();
        return;
    };

    // here just to make sure we can open the repo
    Repository::open(&path).unwrap();

    println!("Serving repo {} on port 4000", path);
    Server::http(move |req: Request, res: Response<Fresh>| {
        let url = match req.uri {
            RequestUri::AbsolutePath(ref url) => url.trim_left_matches('/'),
            _ => panic!(),
        };
        let filename = match url {
            "" => "index.html",
            s => s,
        };

        //let mut res = res.start().unwrap();

        let repo = Repository::open(&path).unwrap();
        let blob = repo.find_reference("refs/heads/gh-pages")
            .and_then(|r| r.target().ok_or(Error::from_str("reference is not direct")))
            .and_then(|commit_id| repo.find_commit(commit_id))
            .and_then(|commit| commit.tree())
            .and_then(|tree|      tree.get_path(Path::new(&filename)))
            .and_then(|entry|     repo.find_blob(entry.id()));

        match blob {
            Err(e) => {
                internal_error(res, e);
            },
            Ok(b) => {
                res.send(b.content()).unwrap();
            }
                
        };
    }).listen("127.0.0.1:4000").unwrap();
}
