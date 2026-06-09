{
  description = "Auto-generated Crossplane provider for Akeyless (regenerated via iac-forge --backend crossplane from akeyless-terraform-resources TOML specs + akeyless OpenAPI 3.0 spec)";
  inputs = {
    nixpkgs.follows = "substrate/nixpkgs";
    substrate = { url = "github:pleme-io/substrate";};
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs: (import "${inputs.substrate}/lib/repo-flake.nix" {
    inherit (inputs) nixpkgs flake-utils;
  }) {
    self = inputs.self;
    language = "go";
    builder = "devShell";
    pname = "crossplane-akeyless";
    description = "Auto-generated Crossplane provider for Akeyless";
  };
}
