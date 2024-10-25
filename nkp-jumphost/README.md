# Terraform configuration files for creating jumphost

1. Upload NKP Rocky Linux image to PC and make a note of the UUID
1. Update `jumphostvm_config_sample.yaml` to match your environment
1. Rename `jumphostvm_config_sample.yaml` to `jumphostvm_config.yaml`
1. Initialize, validate, plan and apply the configuration. 

    ```
    terraform init
    terraform validate
    terraform plan
    terraform apply
    ```