# ---------------------------------------------------------------
# Outputs — printed after `terraform apply`
# Use these to connect kubectl and verify your cluster
# ---------------------------------------------------------------

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint (kubectl talks to this)"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "vpc_id" {
  description = "VPC ID — useful if you add RDS, ElastiCache, etc. later"
  value       = module.vpc.vpc_id
}

output "configure_kubectl" {
  description = "Step 1: run this to add the cluster to ~/.kube/config"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "kubectl_context" {
  description = "Step 2: context name — use with kubectl config use-context"
  value       = module.eks.cluster_arn
}

