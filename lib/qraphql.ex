defmodule GraphQL do
  @moduledoc false



  defdelegate init(opts), to: GraphQL.Schema

  defdelegate query(query, operation, variables \\ %{}), to: GraphQL.Query
end
