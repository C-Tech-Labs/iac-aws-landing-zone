# Architecture

```
flowchart TD
    Org["AWS Organization"] --> Dev["Development Account"]
    Org --> Prod["Production Account"]
    Dev --> VPCDev["VPC Module"]
    Prod --> VPCProd["VPC Module"]
    Dev --> SecDev["Security Module"]
    Prod --> SecProd["Security Module"]
    Dev --> BaseDev["Account Baseline Module"]
    Prod --> BaseProd["Account Baseline Module"]
```

This diagram illustrates a high‑level view of the landing zone with an AWS Organization containing multiple accounts. Each account provisions networking (VPC), security (IAM & GuardDuty), and account baseline modules. Additional modules and policies can be layered as needed to support new services and controls.
