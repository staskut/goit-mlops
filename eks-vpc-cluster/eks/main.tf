module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"


  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  create_kms_key = false
  cluster_encryption_config   = []

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }

  eks_managed_node_groups = {
    cpu-nodes = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      labels = {
        workload = "cpu"
      }
      tags = {
        Name = "cpu-node-group"
      }
    }

    gpu-nodes = {
      instance_types = ["g4dn.xlarge"] # or p3.2xlarge if available
      ami_type       = "AL2_x86_64_GPU"
      min_size       = 0
      max_size       = 2
      desired_size   = 0
      labels = {
        workload = "gpu"
      }
      tags = {
        Name = "gpu-node-group"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}