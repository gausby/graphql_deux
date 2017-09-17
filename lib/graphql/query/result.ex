defmodule GraphQL.Query.Result do
  @moduledoc """
  The result of running a query
  """

  defstruct [
    data: nil, aux: nil, errors: nil
  ]
end
