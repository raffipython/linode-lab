# Linode Lab - Multi-Student Environments (Terraform)

This repo lets you spin up **separate copies** of the same Linode lab for `student1` through `student5`.
Each student has an **independent Terraform state file**, so applying for one student will not touch the others.

## Quick start (choose a student)

```bash
cd envs/student3
terraform init
terraform apply
```

Destroy only that student's lab:

```bash
cd envs/student3
terraform destroy
```

## Where state lives

Local state files are stored in `state/`:

- `state/student1.tfstate`
- ...
- `state/student5.tfstate`

## Customizing uniqueness

Resource labels include `env_suffix` (e.g. `-student3`) so Linode label collisions are avoided.

If you add new Linode resources that require unique names (instances, VPCs, subnets, volumes, etc.),
append `${var.env_suffix}` to their labels too.
