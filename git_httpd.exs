#!/usr/bin/env elixir

# This is a bit of a pain to get running, as there is no global
# dependency installation. Download cowboy, mimetypes and geef, and
# point the run-ex.sh script there.

defmodule GitHttpd.Util do
  def repo_path do
    case System.get_env("GIT_HTTPD_ROOT") do
      nil ->
        System.cwd!()
      cwd ->
        cwd
    end
  end

  def refname do
    case System.get_env("GIT_HTTPD_BRANCH") do
      nil ->
        "refs/heads/gh-pages"
      branch ->
        "refs/heads/" <> branch
    end
  end

  def resolve_path(path) do
    case String.next_codepoint(path) do
      { _, "" } ->
        "index.html"
      { _, rest} ->
        rest
    end
  end
end

defmodule GitHttpd.Handler do
  alias GitHttpd.Util
  alias :cowboy_req, as: Req
  use Geef

  def init(_transport, req, []) do
    case Repository.open(Util.repo_path) do
      {:ok, repo} ->
        {:ok, req, repo}
      error = {:error, _} ->
        error
    end
  end

  def handle(req, repo) do
    { path, req} = Req.path(req)
    Reference[target: target] = Reference.lookup!(repo, Util.refname) |> Reference.resolve!
    { :ok, commit } = Commit.lookup(repo, target)
    { :ok, tree } = Tree.lookup(repo, Commit.tree_id(commit))
    resolved_path = Util.resolve_path(path)
    { status, body } =
      case Tree.get(tree, resolved_path) do
        { :error, _ } ->
          {404, ""}
        { :ok, TreeEntry[id: id] } ->
          { :ok, blob } = Blob.lookup(repo, id)
          { 200, Blob.content(blob) }
      end
    type =
      case :mimetypes.filename(resolved_path) do
        [h | _] -> h
        mt -> mt
      end

    fields = [{"Content-Type", type}]
    {:ok, req} = Req.reply(status, fields, body, req)
    {:ok, req, repo}
  end

  def terminate(_reason, _req, repo) do
    Repository.stop(repo)
    :ok
  end
end

defmodule GitHttpd.App do
  alias :cowboy_router, as: Router

  def start() do
    :application.start(:crypto)
    :application.start(:cowlib)
    :application.start(:ranch)
    :application.start(:cowboy)
    :application.start(:mimetypes)

    dispatch = Router.compile([
      {:_, [{:_, GitHttpd.Handler, []}]}
    ])
    {:ok, _} = :cowboy.start_http(:http, 100, [port: 8080], [env: [dispatch: dispatch]])
  end
end

GitHttpd.App.start()

:timer.sleep(:infinity)
