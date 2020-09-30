defmodule JSONTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Transponder.JSON

  defmodule TestView do
    use Phoenix.View, root: "test/support"

    def render("index.json", %{response: response}) do
      response
    end

    def render("show.json", %{response: response}) do
      response
    end

    def render("errors.json", %{changeset: changeset}) do
      Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    end

    defp translate_error({message, values}) do
      Enum.reduce(values, message, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end
  end

  test "responds to {:error, :not_found} with 404" do
    conn = build_conn(:get, "/any_action")
    conn = JSON.respond(:any_action, conn, {:error, :not_found})

    assert conn.status == 404
    assert conn.resp_body == ~s|{"message":"Not found"}|
  end

  test "responds to {:error, changeset} with 422" do
    conn = build_conn(:get, "/any_action")
    conn = JSON.respond(:any_action, conn, {:error, FakeSchema.changeset()})

    assert conn.status == 422
    assert conn.resp_body == ~s|{"name":["can't be blank"]}|
  end

  test "responds to create {:ok, reponse} with 201" do
    conn = build_conn(:post, "/any_action")
    conn = JSON.respond(:create, conn, {:ok, %{id: 123}})

    assert conn.status == 201
    assert conn.resp_body == ~s|{"id":123}|
  end

  test "responds to show {:ok, reponse} with 200" do
    conn = build_conn(:post, "/any_action")
    conn = JSON.respond(:show, conn, {:ok, %{id: 123}})

    assert conn.status == 200
    assert conn.resp_body == ~s|{"id":123}|
  end

  test "responds to index {:ok, reponse} with 200" do
    conn = build_conn(:post, "/any_action")
    conn = JSON.respond(:show, conn, {:ok, [%{id: 123}]})

    assert conn.status == 200
    assert conn.resp_body == ~s|[{"id":123}]|
  end

  test "responds to unknown response with 500" do
    conn = build_conn(:get, "/any_action")
    conn = JSON.respond(:any_action, conn, :rubbish)

    assert conn.status == 500
    assert conn.resp_body == ~s|{"message":"Unknown error. Please contact support."}|
  end

  defp build_conn(method, action) do
    conn(method, action) |> Phoenix.Controller.put_view(TestView)
  end
end
