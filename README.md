# Resilient WordPress Blog on AWS EKS (Terraform & Helm)

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![EKS](https://img.shields.io/badge/Amazon_EKS-FF9900?style=for-the-badge&logo=amazon-eks&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)

This project demonstrates a production-ready, resilient deployment of a WordPress blog on Amazon EKS (Kubernetes), fully provisioned using Infrastructure as Code (Terraform) and packaged with Helm.

---

### 🎥 Live Demo (CI/CD Pipeline)

*(This will be added after we complete Phase 4: CI/CD)*

---

### 🏗️ Architecture

This project provisions the following infrastructure from scratch:

* **Networking (VPC):** A custom, multi-AZ VPC with public and private subnets, NAT Gateways, and proper route tables to ensure a secure and resilient network foundation.
* **Kubernetes (EKS):** A managed EKS cluster. The worker nodes (`t2.micro`) run in private subnets for security.
* **Database (RDS):** A managed MariaDB instance (`db.t3.micro`) on AWS RDS. It is placed in private subnets and is only accessible from the EKS cluster via a dedicated security group.
* **Storage (EBS):** The EKS cluster is configured with the `aws-ebs-csi-driver` add-on, allowing WordPress pods to dynamically provision and use Persistent Volumes (EBS) for storing user-uploaded files.

![Architecture Diagram (Simple)](https://i.imgur.com/EXAMPLE_DIAGRAM.png) *(This is a placeholder - we can generate a diagram later)*

---

### ✨ Key Features & Technologies

* **Infrastructure as Code (Terraform):** The *entire* infrastructure (VPC, EKS Cluster, Node Groups, RDS Database, IAM Roles, OIDC provider) is 100% automated with Terraform.
* **Kubernetes Orchestration (EKS):** Deployed a containerized, stateful application (WordPress) with 2 replicas for high availability.
* **Dynamic Storage (EBS CSI Driver):** Solved the complex EKS stateful-set problem by correctly provisioning the `aws-ebs-csi-driver` add-on with the required IAM OIDC provider and service account roles, enabling dynamic `PersistentVolumeClaim` (PVC) fulfillment.
* **Package Management (Helm):** Packaged the WordPress deployment into a clean, reusable Helm chart. This chart is configured to connect to the *external* (RDS) database, a common real-world scenario.
* **Security:** Followed best practices by placing all critical components (EKS nodes, RDS database) in private subnets, using security groups to enforce strict firewall rules.

---

### 🚀 How to Run

1.  **Prerequisites:**
    * AWS Account & configured AWS CLI
    * Terraform
    * `kubectl`
    * `helm`

2.  **Provision Infrastructure:**
    ```bash
    cd terraform
    terraform init
    terraform apply
    ```

3.  **Configure `kubectl`:**
    ```bash
    aws eks --region eu-central-1 update-kubeconfig --name main-cluster
    kubectl get nodes
    ```

4.  **Get RDS Endpoint:**
    ```bash
    RDS_HOST=$(terraform output -raw rds_endpoint | cut -d: -f1)
    ```

5.  **Deploy WordPress:**
    ```bash
    cd ../helm
    helm install my-blog ./wordpress-blog \
      --set wordpress.externalDatabase.host=$RDS_HOST \
      --set wordpress.externalDatabase.password="YourSuperSecurePassword123!"
    ```

6.  **Get Load Balancer URL:**
    ```bash
    kubectl get service my-blog-wordpress-service -w
    ```
    *Wait for the `EXTERNAL-IP` to appear, then paste it into your browser.*

---

*(This section to be added after Phase 4)*
### ⚙️ CI/CD Pipeline (GitHub Actions)
...