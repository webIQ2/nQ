# VyOS one-click v2 findings

This version incorporates the validated lessons from the first single-NIC proof-of-concept:

- opposite-spoke UDRs are created automatically through the VyOS private IP
- test VM default size is `Standard_D2s_v3`
- forced internet egress through VyOS stays disabled by default
- test VMs remain private by default
- the deploy script auto-generates an SSH key if Cloud Shell starts empty
- the deploy script rejects placeholder admin IP values
- the guest probe log records HTTP status codes instead of failing cloud-init

This package is still a **single-NIC VyOS proof-of-concept**, not the final multi-NIC production pattern.
