# PDND Interoperability SignalHub Infrastructure

## Introduction

This repository contains the Terraform implementation (on AWS) for the PDND Interoperability SignalHub infrastructure.

About the project:

[PDND Interoperability landing page](https://interop.pagopa.it)

[SignalHub Operating Manual](https://developer.pagopa.it/pdnd-interoperabilita/guides/PDND-Interoperability-Operating-Manual/v1.0/technical-references/signal-hub)

## Required tools

### Terraform version management

`tfenv` is used to manage Terraform versions using a version file located in `src/.terraform-version`.
You can also put multiple versions of that file in the subfolders (in case different states require different TF versions), and tfenv will read the closest one.

1. Install [tfenv](https://github.com/tfutils/tfenv)
2. Run:
```bash
cd src/
tfenv install # will read the version from .terraform-version
```

### VPN 

[AWS Client VPN](https://aws.amazon.com/vpn/client-vpn-download) is used to establish a VPN connection to the VPC, it supports both mutual authentication and SAML authentication.

The current code uses mutual authentication for non-production environments and SAML auth for production.
VPN credentials (used by mutual authentication) can be generated using `easyrsa3` as suggested by [AWS documentation](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-auth-mutual-enable.html).

### PostgreSQL

DB users are managed by a custom Terraform module that uses `psql` to run SQL statements.

### tf-summarize (optional)

[tf-summarize](https://github.com/dineshba/tf-summarize) is used in our Terraform wrapper script (see following sections) to summarize the TF plan output.

## Project structure

The code is currently organized into multiple Terraform states:

- `src/init` manages the Terraform backend resources necessary for the [remote state](https://developer.hashicorp.com/terraform/language/backend/s3).
- `src/main/core` manages the core AWS resources.
- `src/main/k8s` manages the internal Kubernetes resources.

Each state has an `env/` folder that contains one subfolder (e.g. `env/dev/`) for each environment where the state needs to be deployed.
The environment subfolder contains the TF backend configuration and TF variables values for that specific environment.

We use a wrapper script `src/terraform.sh` (referenced by all states) to run Terraform commands on an environment with simplified syntax, for example:
```bash
cd src/main/core
./terraform.sh plan dev # will use ./env/dev/
```

You can also get a concise plan output by running `./terraform.sh summ dev` (requires tf-summarize, see previous section).

ℹ️  about file names: we use a numeric prefix on each Terraform file (e.g. `10-vpc.tf`) to provide a hint about "layers" (lowest = inner foundation, e.g. network) to the readers.
Terraform doesn't actually use this prefix when calculating the plan, instead it builds a dependency graph.

## External dependencies

Some resources are managed using custom reusable modules from [infra-commons](https://github.com/pagopa/interop-infra-commons/tree/main/terraform/modules) (e.g. PostgreSQL users).

```terraform
module "example" {
  source = "git::https://github.com/pagopa/interop-infra-commons//[PATH_TO_MODULE]?ref=[TAG]"
  ...
}
```

⚠️  it's highly recommended to pin the module to a tag (currently commit hashes are not supported by Terraform).

## Deploy steps

The project should be deployed in the following order:

0. Before deploying any state, reset the values inside the files in `env/` since most of those values will be different for you.
    - a list of variables and their description can be found in `98-variables.tf` in each state.
    - some variables have already been reset (e.g. Github repos names, to avoid giving unintended permissions to our repos)
1. `init` state to setup the remote state resources.
    - after the resources are ready, set the appropriate TF backend values in `env/*/backend.tfvars` for all the states
2. `core` state
3. `k8s` state

To deploy a state:
```bash
cd src/main/core
./terraform.sh apply <env> # substitute with the desired environment
```

## Notes about reuse

This implementation may require some changes to work on your account:

- Some resource identifiers are globally unique across all AWS accounts (e.g. S3 bucket names), and they will need to be changed accordingly before your deploy.
    - Bucket names use `local.project` as a prefix, changing that value could be sufficient.
- Access to the AWS accounts is managed through IAM roles (e.g. an organization with AWS SSO and permission sets).
    - AWS users access must be implemented separately
- A DNS domain can be delegated to the production AWS account, which may delegate (not mandatory) "environment subdomains" to other accounts.
    - For example: `interop.example.com` is delegated to the production account, which then delegates `dev.interop.example.com` to the development account.

## Licensing

This project is licensed under the terms of the **Mozilla Public License Version 2.0 (MPL-2.0)**.
The full text of the license can be found in the [LICENSE](LICENSE) file.
Please see the [AUTHORS](AUTHORS) file for the copyright notice.

