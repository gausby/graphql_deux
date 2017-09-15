defmodule GraphQL.Query do
  @moduledoc false

  def query(query, operation, variables \\ %{}) when is_map(variables) do
    with {:ok, ast} <- :graphql.parse(query),
         ast <- :graphql.elaborate(ast),
         {:ok, %{:ast => ast, :fun_env => fun_env}} <- :graphql.type_check(ast),
         :ok <- :graphql.validate(ast) do
      coerced = :graphql.type_check_params(fun_env, operation, variables)
      context = %{params: coerced, operation_name: operation}
      :graphql.execute(context, ast)
    else
      _ -> nil # todo, handle errors
    end
  end
end
