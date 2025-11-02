# Resilient WordPress on AWS EKS (Full CI/CD & Monitoring)

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![EKS](https://img.shields.io/badge/Amazon_EKS-FF9900?style=for-the-badge&logo=amazon-eks&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

This project demonstrates a production-ready, DevOps-driven deployment of a resilient WordPress blog. The entire infrastructure is provisioned on **Amazon EKS (Kubernetes)**, fully automated with **Terraform**, **Helm**, and **GitHub Actions**.

The pipeline automatically builds the infrastructure from scratch, deploys the application, and sets up a complete monitoring stack, all triggered by a single `git push`.

---

### 🎥 Live Demo

**[>>> WATCH THE DEMO VIDEO HERE <<<](https://youtu.be/pzN2N2qUQcg)**

_(This video demonstrates the full CI/CD pipeline, from a `git push` to an automated `helm upgrade` scaling the WordPress pods, with live monitoring in Grafana.)_

---

### 🏗️ Architecture

This project provisions the following infrastructure from scratch:

- **Networking (VPC):** A custom, multi-AZ VPC with public and private subnets, NAT Gateways, and route tables for a secure network foundation.
- **Kubernetes (EKS):** A managed EKS cluster. The worker nodes (`t3.small`) run in private subnets for security.
- **Database (RDS):** A managed MariaDB instance (`db.t3.micro`) on AWS RDS. It is placed in isolated private subnets and is only accessible from the EKS cluster.
- **Storage (EBS):** The EKS cluster is configured with the `aws-ebs-csi-driver` add-on, allowing WordPress pods to dynamically provision Persistent Volumes (EBS) for storing user-uploaded files.
- **Monitoring:** A dedicated `kube-prometheus-stack` is deployed via Helm, providing cluster-wide metrics to Prometheus and visualization in Grafana.

---

### ✨ Key Features

- **Full CI/CD Automation:** A `git push` to the `main` branch triggers a GitHub Actions workflow that automatically runs `terraform apply` and `helm upgrade` to build, deploy, and update the entire stack.
- **Centralized State Management:** Terraform's state is stored securely and centrally in an **AWS S3 bucket** with state locking via **DynamoDB**. This allows both the CI/CD pipeline and local users to work from a single, consistent "source of truth".
- **Production-Grade Security:**
  - **No Hard-Coded Passwords:** The RDS database password is **not** stored in code. It is injected at runtime from **GitHub Actions Secrets** into both Terraform (as a `sensitive` variable) and Helm.
  - **Private Networking:** All critical components (EKS nodes, RDS database) run in private subnets, inaccessible from the public internet.
- **Full Observability (Monitoring):**
  - **Prometheus** automatically scrapes metrics from all Kubernetes nodes and pods.
  - **Grafana** is deployed with a public-facing Load Balancer and pre-configured dashboards to visualize cluster health, node performance, and WordPress pod (CPU/Memory) usage in real-time.
- **Package Management (Helm):** Both the WordPress application and the `kube-prometheus-stack` are managed as versioned Helm charts for easy, repeatable deployments.

---

### 🛠️ Technologies Used

- **Cloud Provider:** AWS
- **IaC (Infrastructure as Code):** Terraform
- **Orchestration:** Kubernetes (AWS EKS)
- **CI/CD:** GitHub Actions
- **Package Management:** Helm
- **Monitoring:** Prometheus & Grafana
- **Application:** WordPress, MariaDB (AWS RDS)

---

### 🚀 How to Reproduce

This project is fully automated. No manual `terraform apply` is needed.

1.  **Fork this Repository.**
2.  **Create the Terraform Backend:**
    - In your AWS account, manually create one **S3 bucket** (with versioning enabled) and one **DynamoDB table** (with a partition key named `LockID`).
    - Update the `terraform/backend.tf` file with your new bucket and table names.
3.  **Set Up GitHub Secrets:**
    - In your AWS account, create an IAM User with `AdministratorAccess` and get its Access Key.
    - In your forked GitHub repo, go to **Settings** > **Secrets and variables** > **Actions**.
    - Create the following 3 repository secrets:
      - `AWS_ACCESS_KEY_ID`: The Access Key ID for your IAM user.
      - `AWS_SECRET_ACCESS_KEY`: The Secret Access Key for your IAM user.
      - `DB_PASSWORD`: A strong, unique password you create for the RDS database.
4.  **Add Your IAM User to EKS (Recommended):**
    - Run `aws sts get-caller-identity` on your local machine to get your local user's ARN.
    - Paste this ARN into the `.github/workflows/deploy.yml` file at the `Add local user to EKS aws-auth` step. This will grant your local `kubectl` admin access to the cluster.
5.  **Push to `main`:**
    - Commit and push your changes (especially to `backend.tf`).
    - Go to the **Actions** tab in your repo. The pipeline will now build the entire infrastructure (15-20 minutes).

---

### 🎓 Key Learnings & Challenges

- **EKS/VPC Deletion Dependencies:** A classic Terraform challenge where Network Interfaces (ENIs) provisioned by the EKS/Load Balancer controller block the `terraform destroy` of the VPC. This highlights the complex dependency graph of managed Kubernetes.
- **Centralized State Management:** Solved the "lost state" problem where the CI/CD pipeline and a local machine had different, conflicting states. Implementing the S3/DynamoDB backend was the critical solution for a single source of truth.
- **CI/CD-Managed Permissions:** By default, only the creator of the EKS cluster (the GitHub Actions runner) has admin rights. This was solved by adding an `eksctl iamidentitymapping` command to the pipeline, which programmatically grants admin access to a specified local user.

---

### 🧹 How to Destroy

Thanks to the S3 backend, you can destroy all infrastructure created by the pipeline directly from your local machine.

```bash
# Navigate to the terraform directory
cd terraform

# Initialize and connect to the S3 backend
terraform init

# Destroy all resources
terraform destroy -auto-approve
```
