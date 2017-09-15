# this is currently a bit messy, these modules should of course not
# live here :)

defmodule TShirt do
  defstruct [
    motive: "Elixir Logo",
    size: "TSHIRT_SIZE_MEDIUM",
    id: nil
  ]

  def execute(_ctx, %__MODULE__{motive: motive}, "motive", _args) do
    {:ok, motive}
  end

  def execute(_ctx, %__MODULE__{size: size}, "size", _args) do
    {:ok, size}
  end
end

defmodule Person do
  defstruct [
    name: nil,
    age: nil,
    id: nil,
    tshirt: %TShirt{}
  ]

  def execute(_ctx, obj, "id", _args) do
    {:ok, obj.id}
  end
  def execute(_ctx, %{name: name}, "name", _args) do
    {:ok, name}
  end
  def execute(_ctx, %{age: age}, "age", _args) do
    {:ok, age}
  end
  def execute(_ctx, %{tshirt: tshirt}, "tshirt", _args) do
    {:ok, tshirt}
  end
end

defmodule Resolver.Query do
  def execute(_ctx, :none, "node", %{"id" => id}) do
    {:ok, %Person{name: "martin", id: id, age: 8}}
  end
end

defmodule Resolver.Mutation do
  def execute(%{op_type: :mutation}, _obj, "createTShirt", %{"input" => args}) do
    {:ok, %{"tshirt" => %TShirt{motive: args["motive"], size: args["size"]}}}
  end
end

defmodule Resolver.Default do
  # this might be a bit too much of a hack...I tried to make something
  # that would map structs to their module, but I don't know if this
  # is good for all cases.
  def execute(_ctx, %{__struct__: _} = obj, field, _args) do
    try do
      value = Map.get(obj, String.to_existing_atom(field), :null)
      {:ok, value}
    catch
      ArgumentError -> {:error, :null}
    end
  end

  def execute(_ctx, %{"tshirt" => obj}, "tshirt", _args) do
    {:ok, obj}
  end

  def execute(_ctx, _obj, field, _args) do
    {:error, {:unknown_field, field}}
  end
end

defmodule Scalar.Default do
  def input(_type, value) do
    {:ok, value}
  end
  def output(_type, value) do
    {:ok, value}
  end
end

defmodule Interface.Default do
  def execute(%{:__struct__ => type}) do
    type = Module.split(type) |> Enum.join(".") |> String.to_existing_atom()
    {:ok, type}
  end
  def execute(otherwise) do
    {:error, {:unknown_type, otherwise}}
  end
end

defmodule Enum.Default do
  def input("TShirtSize", enum) do
    {:ok, enum}
  end

  def output("TShirtSize", enum_name) do
    {:ok, enum_name}
  end
  def output(_default, enum) do
    {:error, {:unknown_enum, enum}}
  end
end

defmodule Union.Default do
  def execute(otherwise) do
    {:error, {:unknown_type, otherwise}}
  end
end

defmodule GraphqlDeuxTest do
  use ExUnit.Case
  use Plug.Test

  doctest GraphqlDeux

  # schema would of course be read by the File-module
  @opts GraphqlDeux.init(
    [ schema: """
      +description(text: "Relay Modern Node Interface")
      interface Node {
        +description(text: "Unique Identity of a Node")
        id: ID!
      }

      type Query {
        +description(text: "Relay Modern specification Node fetcher")
        node(id: ID!): Node
      }

      type Mutation {
        dummy : Node
        +description(text: "Introduce a new tshirt to the system")
        createTShirt(input: CreateTShirtInput!): CreateTShirtPayload
      }

      type Person implements Node {
        id: ID!
        name: String
        age: Int
        tshirt: TShirt
      }

      type TShirt implements Node {
        id: ID!
        size: TShirtSize
        motive: String
      }

      enum TShirtSize {
        TSHIRT_SIZE_EXTRA_SMALL
        TSHIRT_SIZE_SMALL
        TSHIRT_SIZE_MEDIUM
        TSHIRT_SIZE_LARGE
        TSHIRT_SIZE_EXTRA_LARGE
      }

      input CreateTShirtInput {
        clientMutationId: String
        size: TShirtSize
        motive: String
      }

      type CreateTShirtPayload {
        clientMutationId: String
        tshirt: TShirt
      }
      """,
      mapping: %{ scalars: %{ default: Scalar.Default },
                  interfaces: %{ default: Interface.Default },
                  unions: %{ default: Union.Default },
                  enums: %{ default: Enum.Default },
                  objects: %{
                    Query: Resolver.Query,
                    Mutation: Resolver.Mutation,
                    Person: Person,
                    TShirt: TShirt,
                    default: Resolver.Default
                  }
      }
    ])

  test "make a query" do
    conn = conn(:post, "/",
      %{ operation_name: "Test",
         query: """
         query Test($id : ID!) {
           node(id: $id) {
             ... on Person {
               id
               name
               age
               tshirt {
                 motive
                 size
               }
             }
           }
         }
         """,
         variables: %{"id" => "5"}
      })
    foo = GraphqlDeux.call(conn, @opts)
    assert {:ok, json} = JSX.decode(foo.resp_body)
    assert %{"node" => %{"age" => 8, "tshirt" => _test}} = json
    # printing to std so one can inspect the output by running the
    # tests for science
    IO.inspect json
  end

  test "make a mutation" do
    conn = conn(:post, "/",
      %{ operation_name: "CreateTShirt",
         query: """
         mutation CreateTShirt($input: CreateTShirtInput!) {
           createTShirt(input: $input) {
             tshirt {
               motive
               size
             }
           }
         }
         """,
         variables: %{
           "input" => %{
             "size" => "TSHIRT_SIZE_LARGE",
             "motive": "Motorcycles and Skulls on FIRE!"
           }
         }
      })
    foo = GraphqlDeux.call(conn, @opts)
    IO.inspect JSX.decode(foo.resp_body)
  end
end
