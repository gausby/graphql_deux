defmodule GraphQL do
  @moduledoc false

  defdelegate init(opts), to: GraphQL.Schema

  def query(query, operation, variables \\ %{}) do
    GraphQL.Query.run(query, operation, variables)
  end
end
