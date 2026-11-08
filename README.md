# fman API Contract

This repository contains values shared by `fman-api` and the `fman` desktop application.
`enums.json` is the machine-readable enum contract, and this README also documents the settings
sync payload. The contract has no version field because each consumer pins it through its
`contract/` Git submodule commit.

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

## Settings sync

Both operations require the fman account bearer token. The API scopes every document to the user
identified by that token and stores one document per `(user, os, kind)`.

### Kinds

`os` is `Linux`, `Mac` or `Windows`. `kind` is one of these `SyncedSettingsKind` values:

| `kind` | fman user file | Required top-level JSON type of `content` |
| --- | --- | --- |
| `key_bindings` | `Key Bindings (<OS>).json` | array |
| `viewer_key_bindings` | `Viewer Key Bindings (<OS>).json` | array |
| `command_titles` | `Command Titles (<OS>).json` | object |
| `command_keywords` | `Command Keywords (<OS>).json` | object |

### Document shape

Both operations return a document with this shape:

```json
{
  "os": "Windows",
  "kind": "key_bindings",
  "revision": 3,
  "content": [{"keys": ["Ctrl+Q"], "command": "quit"}],
  "updated_at": "2026-11-08T17:00:00+00:00"
}
```

`revision` is an integer that starts at 1 and increases with each accepted save. `content` is
the whole settings file as fman writes it, represented as parsed JSON rather than an escaped
string. The API checks only the required top-level type and that the encoded `content` is no
larger than 262144 bytes (256 KiB); it does not validate individual entries.

### Load

`GET /api/v1/settings/{os}/{kind}` returns `200` with the document. When no document has been
stored, it returns `404` with `{"error": true, "message": "..."}`.

### Save

`PUT /api/v1/settings/{os}/{kind}` accepts this body:

```json
{
  "base_revision": 3,
  "content": [{"keys": ["Ctrl+Q"], "command": "quit"}]
}
```

`base_revision` is the revision the client last loaded or saved, or `null` when it has none. The
first save therefore uses `null`. A save is accepted when `base_revision` matches the stored
revision, or when it is `null` and no document is stored. The API returns `200` with the new
document.

If another installation saved since the client's last load, the API returns `409` with
`{"error": true, "message": "...", "current": <stored document>}` and writes nothing. The
client shows the user the choice and, to keep its own copy, saves again with `current.revision`
as `base_revision`.

There is no delete operation.

### Errors

- An unknown `os` or `kind` returns `404` because the route does not match.
- Wrong `content` type, content larger than 262144 encoded bytes, a missing field, or a
  non-integer non-null `base_revision` returns `422` in the existing
  `{"error": true, "message": "...", "details": {"<field>": "<message>"}}` form, where
  `details` maps each invalid field to its error message.
- A missing or invalid bearer token returns `401`.

### Change order

`SyncedSettingsKind` and `SyncedSettingsOs` are `client_to_api` values: add a new kind or OS here
and in `fman-api` before `fman` sends it.
