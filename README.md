# GraphQL-Erlang Plug for Elixir Compatibility

This repo is a work in progress plug for the graphql-erlang project.


## Introduction

As the name implies `graphql-erlang` is a GraphQL engine written for
the Beam (the Erlang VM). While the Erlang project has not reached
*one-point-oh* yet it would be interesting to see how this project
would integrate with the Elixir and its ecosystem.

`graphql-erlang` is and open source project, mainly developed at
ShopGun ApS who runs it in production and sponsors its development.

The graphql-erlang project is freely available and is released under
an open source license:

  - https://github.com/shopgun/graphql-erlang


## graphql-erlang

While there are other GraphQL engines in the making for the Elixir
ecosystem the graphql-erlang has its place. It takes an alternative
approach to defining a GraphQL server that most of the other
implementations I have seen, notably it parses a schema file and the
programmer is responsible for mapping the objects, «enums», unions,
and interfaces to modules defining their behaviour. Essentially the
GraphQL engine takes care of the requests, enforcing and validates the
data types going in and out of it, the user defines the logic that
fulfills the inquiry.

The approach taken by graphql-erlang makes it explicit how many
processes are spawned when a query is resolved in parallel because it
is the programmer who explicitly spawn processes and reply back to the
graphql-engine with a result and a reply token.

Besides the explicitness of process, implementing a resolver relies
heavily on pattern-matching. The whole experience is designed to
compliment how Erlang works internally. A programmer with a good grasp
of the Erlang process model should feel very much at home with
graphql-erlang thus preventing the dreaded context switch.

The GraphQL Erlang Tutorial is a small book about the system, and
reading it is highly recommended:

  - https://github.com/shopgun/graphql-erlang-tutorial


## What I currently have

As of now I have a plug that initialize a GraphQL schema with
bindings. It sets up the build and validation pipelines for both the
initialization of the server and the individual requests.

The configuration happens by passing arguments to the plug. Usage can
be seen in the project test.


## Challenges

While it is pretty straight forward to setup the compilation steps I
have stumbled upon the following challenges.

Feel free to open issues responding to particular challenges by
including the headline in the title.


### «Usability»

While I think I have a fairly good grasp of Elixir I would like to
hear peoples opinion on what a good Elixir integration would look
like.

I currently have a Plug, and I would like to be able to add it to a
Phoenix route which could handle the GraphQL requests. I guess some
macros that setup some good defaults for resolvers could be cool and
aid building GraphQL servers in general.

This needs some R&D.


### Error reporting

We need to work on better error reporting from the GraphQL engine
itself, but the wrapper could perhaps report errors in a format that
is better suited for Elixir.

This needs some R&D.


### Encoding to JSON

Graphql-erlang uses the atom `null` to communicate no data. This is
native to both JSON, the GraphQL spec, and quite common in the Erlang
ecosystem. This means the final data-structure returned by GraphQL
will contain `:null` atoms. This presents us with a problem: the atom
`:null` is cast to the string `"null"` in all the Elixir JSON encoders
I have looked at. This is because `nil` is special in Elixir, and thus
is the one being translated into `null`—other special atoms are `true`
and `false` who will be translated into their corresponding Boolean
values.

We could traverse the returned data-structures and replace `nil`s with
`:null`s before passing them to one of the JSON encoders, but this
would result in an unnecessary overhead—switching to using the atom
nil in the GraphQL engine instead would present the same problem, only
on the Erlang side. In other words: One must convert.

A more reasonable solution could be to handle `:null` as a special
case in Poison. This would require one line of code but one would not
be able to encode and decode to the same data structure—I don't know
if this is a requirement for Poison, I would assume converting a
MapSet to JSON and converting it back would result in a different data
structure anyways.

My argument for handling `:null -> null` as a special case in Poison
is interopability with other Erlang modules. I know of people who have
had to deal with this building CouchDB adaptors and other JSON
adaptors built on top of the Erlang libraries. In short this is not a
unique problem.  I have solved the problem by using the `jsx` JSON
encoder, the same encoder we use at ShopGun, because it convert
`:null` to `null` in the resulting JSON. That is why exjsx has been
listed as a dependency.

N.b: it would be nice to be able to change the JSON encoder.


### Mapping the schema to modules

This needs a bit of thinking and R&D. I would not like people to
create modules called «:Person» for mapping with a «Person»-type in
the GraphQL schema.

One thing that could happen as well is to create the mapping table
from a naming structure (kinda like a Phoenix router) but I don't like
this because it makes the system a bit less transparent.


### Project name

The project is called GraphqlDeux at the moment. This is because this
is my second attempt of creating this.

A better name would be cool; preferably one that makes for a nice logo
that would go well on mugs and tshirts. :D
