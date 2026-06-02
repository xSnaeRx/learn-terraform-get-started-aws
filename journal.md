# Journal

## "Day 1"

    - Set up SSH key authentication with GitHub
    - Connected VS Code to a GitHub repository
    - Learned core git commands (clone, add, commit, push, pull)
    - Initialized a Terraform project on AWS,
    
# 2026-06-02 — Terraform AWS: Manage & Destroy Infrastructure

**Source:** [HashiCorp Developer — Get Started: AWS](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/)  
**Labs completed:** Manage Infrastructure · Destroy Infrastructure  
**Time estimate:** ~14 min

---

## What I Did

Picked up where the *Create* lab left off — an EC2 instance running in `us-west-2` managed by a local Terraform workspace. Worked through the next two tutorials in the AWS Get Started series.

---

## Manage Infrastructure

### Input Variables

Extracted hard-coded values out of `main.tf` into a dedicated `variables.tf` file, defining `instance_name` and `instance_type` with defaults. Updated the `aws_instance` resource block to reference `var.instance_name` and `var.instance_type`.

Key takeaway: variables can be overridden at plan/apply time without touching config files:

```bash
terraform plan -var instance_type=t2.large
```

Terraform flagged the instance for an in-place update and noted that the public IP and hostname would be `(known after apply)` since AWS reassigns those on instance replacement.

### Output Values

Created `outputs.tf` and defined an `instance_hostname` output exposing the EC2 instance's private DNS. After applying, Terraform printed the output directly in the terminal and stored it in state. Can be retrieved anytime with:

```bash
terraform output
```

### Modules

Added the `terraform-aws-modules/vpc/aws` module to `main.tf` to provision a full VPC (two private subnets, one public subnet, internet gateway, route tables, etc.) and moved the EC2 instance into it.

Because a new module was introduced, `terraform init` was required again to download it before applying. Terraform resolved resource dependencies automatically and executed operations in the correct order — destroyed the old EC2 instance first, then built the VPC, then created the new instance inside it.

After apply, `terraform state list` showed all 17 managed resources, with VPC module resources namespaced under `module.vpc.*`.

---

## Destroy Infrastructure

### Removing a Single Resource

Commented out the `aws_instance.app_server` block in `main.tf` (and the dependent `instance_hostname` output in `outputs.tf` to keep config valid), then ran `terraform apply`. Terraform planned 1 destroy, confirmed, and removed only the EC2 instance — leaving the VPC and networking resources intact.

### Full Workspace Teardown

Ran `terraform destroy` to remove all remaining infrastructure. Terraform planned 15 destroys and executed them in reverse dependency order (route table associations → subnets → internet gateway → route tables → VPC). Completed cleanly with `Destroy complete! Resources: 15 destroyed.`

---

## Commands Used

```bash
terraform init          # re-run after adding new module
terraform plan -var instance_type=t2.large
terraform apply
terraform output
terraform state list
terraform destroy
```

---

## Key Concepts Reinforced

- **Variables & outputs** decouple configuration values from resource definitions and make workspaces scriptable/composable.
- **Modules** are reusable resource bundles sourced from the Terraform Registry or local paths; adding one requires re-running `terraform init`.
- **Dependency graph** — Terraform builds one automatically; no manual ordering needed. Resources are created/destroyed in the correct sequence.
- **Removing a resource** from config and applying is the standard workflow for targeted teardown; `terraform destroy` nukes the entire workspace.
- State is the source of truth — Terraform diffs desired state (config) against current state to determine what to create, update, or destroy.

---

## Notes / Thoughts

- Good habit to always run `terraform plan` before `apply`, especially with `-var` overrides, to catch replacements vs. in-place updates early.
- The `terraform state list` command is useful for auditing exactly what's tracked in a workspace — handy before a destroy.
- Module namespacing (`module.vpc.*`) keeps state organized when configs grow; same pattern applies to Helm chart resources in Kubernetes, which maps nicely to prior k8s work.
- Next up: *Collaborate using HCP Terraform* — remote state storage and team workflows.
