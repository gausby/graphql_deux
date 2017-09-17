defmodule GraphQL.Schema do
  @moduledoc false

  defstruct test: nil

  def init(opts) do
    with {:ok, mapping} <- get_mapping(opts),
         {:ok, schema} <- get_schema(opts),
         :ok = :graphql.load_schema(mapping, schema),
         {:ok, root} <- get_root_schema(opts),
         :ok = :graphql.insert_schema_definition(root),
         :ok = :graphql.validate_schema() do
      %__MODULE__{}
    else
      _ -> nil # todo, handle errors
    end
  end

  defp get_mapping(opts) do
    case Keyword.fetch(opts, :mapping) do
      :error -> {:error, :missing_mapping}
      {:ok, value} -> {:ok, value}
    end
  end

  defp get_schema(opts) do
    case Keyword.fetch(opts, :schema) do
      :error -> {:error, :missing_schema}
      {:ok, value} -> {:ok, value}
    end
  end

  @default_root_schema %{
    :query => "Query",
    :mutation => "Mutation",
    :interfaces => ["Node"]
  }
  defp get_root_schema(opts) do
    root_schema = Keyword.get(opts, :root, @default_root_schema)
    {:ok, {:root, root_schema}}
  end
end
