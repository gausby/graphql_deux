defmodule GraphqlDeux do
  @moduledoc """
  Todo, write stuff
  """
  import Plug.Conn

  def init(options) do
    mapping = Keyword.fetch!(options, :mapping)
    schema = Keyword.fetch!(options, :schema)
    root_schema =
      Keyword.get(options, :root,
        {:root, %{ :query => :Query,
                   :mutation => :Mutation,
                   :interfaces => [:Node]
                 }})
    :ok = :graphql.load_schema(mapping, schema)
    :ok = :graphql.insert_schema_definition(root_schema)
    :ok = :graphql.validate_schema()
    options
  end

  def call(conn, opts) do
    with {:ok, query} <- get_query(conn.body_params),
         {:ok, op} <- get_operation(conn.body_params),
         {:ok, ast} <- :graphql.parse(query),
         ast <- :graphql.elaborate(ast),
         {:ok, %{:ast => ast, :fun_env => fun_env}} <- :graphql.type_check(ast),
         :ok = :graphql.validate(ast) do
      variables = Map.get(conn.body_params, "variables", %{})
      coerced = :graphql.type_check_params(fun_env, op, variables)
      context = %{params: coerced, operation_name: op}
      #
      case :graphql.execute(context, ast) do
        %{data: result} ->
          resp_body = :jsx.encode(result)
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp_body)

        # else...
      end
    else
      # handle errors
      {:error, :missing_query} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(302, "Hello world")

      {:error, {:parser_error, error}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, "Hello world")
    end
  end

  defp get_query(%{"query" => query}), do: {:ok, query}
  defp get_query(%{}), do: {:error, :missing_query}

  defp get_operation(%{"operation_name" => op}), do: {:ok, op}
  defp get_operation(%{}), do: {:error, :no_operation_defined}
end
