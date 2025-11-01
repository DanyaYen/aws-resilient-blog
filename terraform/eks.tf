resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}


# --- EKS CLUSTER ---
resource "aws_eks_cluster" "main_cluster" {
  name     = "main-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

    # ---> ДОБАВЬ ЭТУ СТРОКУ <---
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
  ]
}
# --- EKS NODE GROUP ---
resource "aws_eks_node_group" "main_node_group" {
  cluster_name    = aws_eks_cluster.main_cluster.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_role_policy_attachment.eks_cni_policy_attachment,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only_attachment,
  ]
}

# --- IAM OIDC PROVIDER ---
data "tls_certificate" "eks_cluster_thumbprint" {
  url = aws_eks_cluster.main_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_thumbprint.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main_cluster.identity[0].oidc[0].issuer
}

# --- ПАУЗА ---
resource "time_sleep" "wait_for_oidc" {
  create_duration = "60s" # 60 секунд. Если опять упадет, можно увеличить до 90s

  depends_on = [
    aws_iam_openid_connect_provider.eks_oidc_provider
  ]
}

# --- IAM EBS CSI DRIVER---
# --- ИЗМЕНЕН ЭТОТ РЕСУРС ---
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "eks-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc_provider.arn
        },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  # --- ДОБАВЛЕНА ЭТА ЗАВИСИМОСТЬ ---
  # Заставляем саму РОЛЬ ждать, пока 60-секундная пауза не пройдет
  depends_on = [
    time_sleep.wait_for_oidc
  ]
}
# -------------------------

# --- ИЗМЕНЕН ЭТОТ РЕСУРС ---
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name

  # Эта зависимость больше не нужна, т.к. она будет транзитивной:
  # Addon -> Attachment -> Role -> Sleep -> OIDC
  # depends_on = [
  #   time_sleep.wait_for_oidc
  # ]
}
# -------------------------

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main_cluster.name
  addon_name   = "aws-ebs-csi-driver"
  
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn

  # Зависимость от Attachment гарантирует, что все создастся по цепочке
  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy_attachment,
    aws_eks_node_group.main_node_group  # <-- ДОБАВЬ ЭТУ СТРОКУ
  ]
}