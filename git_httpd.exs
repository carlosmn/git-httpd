# This is a bit of a pain to get running. The run-dynamo.sh script
# makes it easier. You need a working version of dynamo somewhere and
# geef built.

defmodule GitHttpd do
  use Dynamo
  use Dynamo.Router

  alias :geef_repo, as: Repo
  alias :geef_ref, as: Ref
  alias :geef_object, as: Object
  alias :geef_commit, as: Commit
  alias :geef_tree, as: Tree
  alias :geef_blob, as: Blob

  config :dynamo, compile_on_demand: false
  config :server, port: 8080

  defp repo_path do
    case System.get_env("GIT_HTTPD_ROOT") do
      nil ->
        System.cwd!()
      cwd ->
        cwd
    end
  end

  defp refname do
    case System.get_env("GIT_HTTPD_BRANCH") do
      nil ->
        "refs/heads/gh-pages"
      branch ->
        "refs/heads/" <> branch
    end
  end

  defp resolve_path(path) do
    case String.next_codepoint(path) do
      { _, "" } ->
        "index.html"
      { _, rest} ->
        rest
    end
  end

  def service(conn) do
    { :ok, repo } = Repo.open(repo_path)
    { :ok, ref } = Ref.lookup(repo, refname)
    { :ok, ref } = Ref.resolve(ref)
    { :ok, commit } = Commit.lookup(repo, Ref.target(ref))
    { :ok, tree } = Tree.lookup(repo, Commit.tree_id(commit))
    case Tree.bypath(tree, resolve_path(conn.path)) do
      { :error, _ } ->
        conn.status(404)
      { :ok, _, _, id, _ } ->
        { :ok, blob } = Blob.lookup(repo, id)
        conn.resp_body(Blob.content(blob))
    end
  end

end

GitHttpd.start_link
GitHttpd.run

:timer.sleep(:infinity)
