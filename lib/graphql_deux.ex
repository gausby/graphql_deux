defmodule GraphqlDeux do
  @moduledoc """
  Todo, write stuff
  """
  import Plug.Conn

  def init(options) do
    GraphQL.init(options)
    options
  end

  def call(conn, _opts) do
    variables = Map.get(conn.body_params, "variables", %{})
    {:ok, query} = get_query(conn.body_params)
    {:ok, operation} = get_operation(conn.body_params)
    %{result: %{data: result}} = GraphQL.query(query, operation, variables)
    resp_body = :jsx.encode(result)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, resp_body)
  end

  defp get_query(%{"query" => query}), do: {:ok, query}
  defp get_query(%{}), do: {:error, :missing_query}

  defp get_operation(%{"operation_name" => op}), do: {:ok, op}
  defp get_operation(%{}), do: {:error, :no_operation_defined}
end
