# crossplane-akeyless

> **★★★ CSE / Knowable Construction.** This repo operates under
> **Constructive Substrate Engineering** — canonical specification at
> [`pleme-io/theory/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md`](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md).
> The Compounding Directive (operational rules: solve once,
> load-bearing fixes only, idiom-first, models stay current, direction
> beats velocity) is in the org-level pleme-io/CLAUDE.md ★★★ section.
> Read both before non-trivial changes.

Auto-generated Crossplane provider for Akeyless. 119 managed-resource
Kinds + ProviderConfig, 727 artifacts (601 .go), 100% `go build ./...`
clean, every controller satisfying `crossplane-runtime` v1.18+'s
`ExternalClient` + `resource.Managed` interfaces.

## Substrate posture

This repo is a **pure autogen output** — no hand-written Go. Inputs:

  1. `../akeyless-terraform-resources/resources/*.toml`  — 119 typed
     resource specs declaring CRUD endpoints + identity + attributes.
  2. `../akeyless-go/api/openapi.yaml`                   — vendored
     akeyless OpenAPI 3.0 spec (also the input to `akeyless-go`'s
     own autogen).
  3. `../akeyless-terraform-resources/provider.toml`     — provider-level
     auth/metadata.

Pipeline:

```
TOML resource specs ─┐
                     ├──► iac-forge → goast typed AST → printed Go
akeyless OpenAPI ────┘     (no format!()-string-of-Go-syntax anywhere)
                                           │
                                           ▼
                              727 artifacts emitted into:
                              ├─ apis/<resource>/v1alpha1/
                              │    ├─ <resource>_types.go        (CRD types)
                              │    ├─ groupversion_info.go       (scheme glue)
                              │    ├─ zz_generated_deepcopy.go   (runtime.Object)
                              │    └─ zz_generated_managed.go    (resource.Managed)
                              ├─ apis/akeyless/v1alpha1/
                              │    ├─ providerconfig_types.go
                              │    ├─ groupversion_info.go
                              │    └─ zz_generated_deepcopy.go
                              ├─ apis/apis.go                    (AddToScheme aggregator)
                              ├─ internal/controller/<resource>/
                              │    └─ controller.go              (ExternalClient impl)
                              ├─ internal/controller/setup.go    (manager wiring)
                              ├─ cmd/provider/main.go            (entry point)
                              ├─ go.mod                           (typed GoMod struct)
                              ├─ helm/Chart.yaml + values.yaml    (typed serde structs)
                              ├─ helm/templates/{deployment,rbac}.yaml
                              └─ package/crds/*.yaml              (CRD YAML)
```

Every `.go` file flows through [`iac-forge::goast`](https://github.com/pleme-io/iac-forge/blob/main/src/goast.rs)
— typed Go AST + printer. Helm metadata flows through typed serde
structs serialized via `serde_yaml_ng`. Helm templates flow through
`serde_yaml_ng::Value` trees with template directives as opaque
string scalars. **Zero `format!()` of Go or YAML syntax** at any
substrate layer — this is the substrate-hygiene-reset directed
2026-05-06 (org-level pleme-io/CLAUDE.md ★★★ section + the
[Constructive Substrate Engineering](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md)
spec).

Hand-edits to generated files are reverted on the next regeneration.
If you need to change behavior, change the TOML spec, the OpenAPI
spec, or extend `iac-forge`'s typed emission surface.

## Regenerating

```bash
make regenerate
```

Under the hood:

```bash
nix shell nixpkgs#openapi-generator-cli --command \
  iac-forge generate \
    --backend crossplane \
    --spec /tmp/akeyless-openapi.json \
    --resources ../akeyless-terraform-resources/resources \
    --provider ../akeyless-terraform-resources/provider.toml \
    --output .forge-gen-out
```

Then promotes `.forge-gen-out/*` to the repo root.

`yq -o json '.' ../akeyless-go/api/openapi.yaml > /tmp/akeyless-openapi.json`
is the upstream-spec → JSON conversion that side-steps
[OpenAPITools/openapi-generator#9203](https://github.com/OpenAPITools/openapi-generator/issues/9203)
(the openapi-generator-cli YAML parser chokes on the akeyless spec's
datetime literals; forge-gen does the transcoding automatically when
spec.path ends in `.yaml`).

### Refreshing the spec from upstream

```bash
cd ../akeyless-go && make regenerate    # bumps OpenAPI snapshot
cd ../crossplane-akeyless && make regenerate
make verify                              # go build ./...
```

## Generator details

| Setting | Value |
|---------|-------|
| Generator | [`pleme-io/iac-forge`](https://github.com/pleme-io/iac-forge) (typed AST + printer) |
| Backend | [`pleme-io/crossplane-forge`](https://github.com/pleme-io/crossplane-forge) (composes types_gen + controller_gen + provider_gen + deepcopy_gen + managed_methods_gen) |
| Module path | `github.com/pleme-io/crossplane-akeyless` |
| Source TOMLs | `pleme-io/akeyless-terraform-resources/resources/*.toml` |
| Source OpenAPI | `pleme-io/akeyless-go/api/openapi.yaml` |
| crossplane-runtime | v1.18.0 (ExternalClient + ExternalDelete + Disconnect + logging.Logger) |
| controller-runtime | v0.19.0 |
| k8s.io/apimachinery | v0.31.0 |

## Coverage

| Surface | Coverage |
|---|---|
| Managed-resource Kinds emitted | 119 / 119 |
| ProviderConfig + Usage | ✓ |
| `apis/...` `go build` clean | ✓ |
| `cmd/provider/main.go` `go build` clean | ✓ |
| Per-resource controller compile clean | **111 / 119 (93.3%)** |
| Per-resource controller body-mapping graduated | 0 (M3.2 work) |
| Per-resource controller stub (compiles + no-ops) | 8 / 119 |
| Helm chart template (Deployment + RBAC + ServiceAccount) | ✓ |

The 8 stubbed controllers cover resources whose SDK body shape requires
heterogeneity the substrate's slice-1 `ResourceShape` doesn't yet
handle:

| Resource | Why stubbed |
|---|---|
| `account_custom_field` | mixed types: `Id int64` on Get/Delete vs `Name string` on Create |
| `certificate` | mixed pointer/value: `GetCertificateValue.Name *string` vs `DeleteItem.Name string` |
| `gateway_migration` | mixed: `Name *string` on Get/Update vs `Id string` on Delete |
| `kmip_client` | mixed pointer/value across CRUD methods |
| `kmip_environment` | singleton bodies (Describe/Delete have no Name field; Setup uses Hostname) |
| `policy` | mixed: `Path` on Create/Update vs `Id` on Get/Delete |
| `role_auth_method_assoc` | composite key (RoleName + AmName) → AssocId on Delete |
| `role_rule` | composite key (RoleName + Path) on Set/Delete |

M3.2 graduates each one as the body-mapping iteration lands. Until
then the stubs satisfy the `ExternalClient` interface (no-op every
method, return empty observations) so the manager registers them and
the rest of the provider works.

## History

This repo's pre-2026-05-06 state lived at tag
[`pre-m5-2026-05-06`](https://github.com/pleme-io/crossplane-akeyless/releases/tag/pre-m5-2026-05-06)
— flat CRD-YAML output only. The 2026-05-06 substrate-hygiene reset +
M5 cycle rebuilt the provider as a complete buildable Go module.
