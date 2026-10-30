<!-- Generated from private documentation source. Do not edit directly. Source SHA256: d5937104c634f456655291699ac15e8ddb9868dc86c0776f6a4fc8baa1149700 -->

# gd-session

Backend-neutral session primitives for Godot 4.

The addon provides a bounded session store behind an injected OS-credential
adapter, a stable random client ID through the same persistence policy, and
explicitly unverified JWT expiry hints. It does not know which backend issued
the session: games own HTTP transport, sign-in, refresh and revoke policy, and
server trust.

## Installation

```sh
gdam install @aviorstudio/gd-session
```

## Quick start

```gdscript
const SessionStoreModule = preload(
	"res://addons/@aviorstudio_gd-session/src/session_store_module.gd"
)
const CredentialAdapter = preload(
	"res://addons/@aviorstudio_gd-session/src/credential_adapter.gd"
)

# Implement this boundary with the target OS credential facility. Its writes
# must be atomic; never bundle an encryption key in the game.
class NativeCredentials extends CredentialAdapter:
	func read_value(key: String) -> Result:
		return Result.new(Status.UNAVAILABLE, "", "connect the platform credential API")
	func write_value(key: String, value: String) -> Result:
		return Result.new(Status.UNAVAILABLE, "", "connect the platform credential API")

var config := SessionStoreModule.SessionStoreConfig.new()
config.native_adapter = NativeCredentials.new()
var store := SessionStoreModule.new(config)
var saved := store.save({"access_token": access_token, "user": user})
if not saved.is_ok():
	push_error(saved.detail)
```

## Modules

Every module is reached by preload; the addon declares no global class names,
which is what lets gdam install it as a dependency of other addons (including
a second, nested copy when exact pins disagree). An addon that depends on
gd-session reaches these scripts through its generated `.gdam/deps.gd`
(`Deps.GdSession_credential_adapter`, `Deps.GdSession_web_memory_adapter`,
and so on); a game preloads them by path as above.

- `src/session_store_module.gd`: store at most 64 KiB of acyclic JSON-compatible data
  (depth 16). Native callers must inject an atomic OS-credential adapter; no
  plaintext or bundled-key fallback exists. Web uses process memory only, so
  values do not survive reload. Migration from a legacy `user://` file occurs
  only after the destination write and readback succeed, and the legacy source
  is retained. `clear()` writes a verified tombstone so retained legacy data
  cannot be remigrated after logout.
- `src/client_id_module.gd`: generate a random ID through the same persistence
  policy. Keys, including quotes and newlines, remain data and are never
  interpolated into JavaScript. Web randomness uses the JavaScript object API,
  not `eval`.
- `src/jwt_module.gd`: decode at most a 16 KiB JWT / 8 KiB payload and return
  typed `VALID`, `EXPIRED`, or `INVALID` expiry metadata. `exp` is required,
  finite, positive, and integral. Default skew is zero; callers may pass a
  nonnegative skew. Every decoded field is explicitly untrusted: this module
  does not verify signatures, authorize, or establish identity.
- `src/credential_adapter.gd`: the persistence boundary the store and client
  ID write through: `read_value(key)` and `write_value(key, value)` each
  return a `Result` with `status` (`OK`, `NOT_FOUND`, `UNAVAILABLE`,
  `INVALID_ARGUMENT`, `IO_ERROR`) and `value`. Native games subclass it with
  the platform keyring. An object crossing an addon boundary is matched by
  those methods, not by `is`, because two copies of this script are two
  classes.
- `src/web_memory_adapter.gd`: the process-memory adapter, the web platform's
  only persistence and the default when a consumer supplies none.

Storage keys are namespaced `gd-session/session/<store_id>` and
`gd-session/client-id/<storage_key>`. A game moving here from a backend-named
addon starts with an empty store and signs in once.

### Policy

- Native persistence requires an injected OS-credential adapter; web
  persistence is memory-only. Browser memory is script-accessible and is not
  a secure keystore. No bundled-key security claim is made.
- Legacy data is never deleted by migration. A destination is usable only
  after a successful commit and readback.

## License

See `LICENSE`.
