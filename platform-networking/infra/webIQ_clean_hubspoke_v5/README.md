# webIQ clean hub-and-spoke v2

This package contains the rebuilt VyOS one-click deployment with the validated findings from the first proof-of-concept baked into the defaults.

## What changed in v2

- built-in inter-spoke UDRs via `10.60.1.4`
- `Standard_D2s_v3` default for both test VMs
- private test VMs by default
- safer deployment script defaults for SSH key and admin IP handling
- decommission and validation helper scripts in `vyos/oneclick`

## Recommended sequence

1. `vyos/oneclick/decommission.sh`
2. `vyos/oneclick/deploy.sh`
3. `vyos/oneclick/validate.sh`
4. guest-level tests with `az vm run-command invoke`
5. freeze evidence and then move to modular deployment
