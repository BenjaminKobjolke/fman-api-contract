# fman API Contract

This repository contains values shared by `fman-api` and the `fman` desktop application.
`enums.json` is the machine-readable enum contract; it has no version field because each
consumer pins the contract through its `contract/` Git submodule commit.

## Enum shape

Each enum is an object with sorted, unique `values`, a `direction`, and a `description` naming
the API field where the enum appears:

```json
{
  "PluginSource": {
    "values": ["catalog", "github"],
    "direction": "api_to_client",
    "description": "PluginListEntry.source"
  }
}
```

## Change order

- For `api_to_client`, update this contract and release clients that know the new value before
  the API emits it.
- For `client_to_api`, update this contract and the API before the client sends the new value.
- To remove a value, stop emitting or accepting it at the API first, remove it from this contract,
  then remove it from clients.
- Never rename a value. Treat a rename as adding a new value and removing the old one.
- Add a shared enum here in the same change that introduces it.

`fman-api` produces and exports these values from its enums. `fman` consumes them and must skip
unknown values rather than failing the full response.
