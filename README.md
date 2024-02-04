
### Fetch GraphQL Schema
Fetch and print the GraphQL schema from a GraphQL HTTP endpoint and make code generation easier

## Quick Start 🚀

### Installing 🧑‍💻

```sh
dart pub global activate fetch_graphql_schema
```

Or install a [specific version](https://pub.dev/packages/fetch_graphql_schema/versions) using:

```sh
dart pub global activate fetch_graphql_schema <version>
```

### Commands ✨

### `fetch_graphql_schema fetch`

```sh
Fetch and print the GraphQL schema from a GraphQL HTTP endpoint.

Usage: fetch_graphql_schema fetch [arguments]
  -h, --help     Print this usage information.
  --[no-]json    Output in JSON format (based on introspection query)
  --url          GraphQL HTTP endpoint to fetch schema
  --header       Add a custom header (ex. 'Authorization=Bearer ABC','Version=2.1.0')

Run "fetch_graphql_schema help" to see global options.
```

#### Usage

```sh
# fetch and print
fetch_graphql_schema fetch

```

---

### `fetch_graphql_schema upgrade`

```sh
Updates Fetch GraphQL Schema CLI to latest version.

Usage: fetch_graphql_schema upgrade [arguments]
-h, --help                               Print this usage information.

Run "fetch_graphql_schema help" to see global options.
```