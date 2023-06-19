# create VPC
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  env          = var.env
  type         = var.type
}

# create security group
module "security_groups" {
  source        = "./modules/security-groups"
  vpc_id        = module.vpc.vpc_id
  project_name  = var.project_name
  ssh_access    = var.ssh_access
  ui_access     = var.ui_access
  hec_access    = var.hec_access
  ingest_access = var.ingest_access
  env           = var.env
  type          = var.type
}

# create ALB
module "alb" {
  source               = "./modules/alb"
  project_name         = var.project_name
  alb_security_group   = module.security_groups.alb_security_group_id
  public_subnet_az1_id = module.vpc.public_subnet_az1_id
  public_subnet_az2_id = module.vpc.public_subnet_az2_id
  public_subnet_az3_id = module.vpc.public_subnet_az3_id
  vpc_id               = module.vpc.vpc_id
  env                  = var.env
  type                 = var.type
}

# create asg
module "asg" {
  source                       = "./modules/auto-scalling"
  idx_instance_type            = var.idx_instance_type
  workstation_instance_type    = var.workstation_instance_type
  sh_instance_type             = var.sh_instance_type
  hf_instance_type             = var.hf_instance_type
  dp_instance_type             = var.dp_instance_type
  public_subnet_az1_id         = module.vpc.public_subnet_az1_id
  public_subnet_az2_id         = module.vpc.public_subnet_az2_id
  public_subnet_az3_id         = module.vpc.public_subnet_az3_id
  workstation_security_group   = module.security_groups.workstation_security_group_id
  alb_security_group           = module.security_groups.alb_security_group_id
  sh_security_group            = module.security_groups.sh_security_group_id
  dp_security_group            = module.security_groups.dp_security_group_id
  hf_security_group            = module.security_groups.hf_security_group_id
  project_name                 = var.project_name
  target_group_arn             = module.alb.target_group_arn
  workstation_desired_capacity = var.workstation_desired_capacity
  idx_desired_capacity         = var.idx_desired_capacity
  sh_desired_capacity          = var.sh_desired_capacity
  hf_desired_capacity          = var.hf_desired_capacity
  dp_desired_capacity          = var.dp_desired_capacity
  workstation_volume_size      = var.workstation_volume_size
  idx_volume_size              = var.idx_volume_size
  sh_volume_size               = var.sh_volume_size
  hf_volume_size               = var.hf_volume_size
  dp_volume_size               = var.dp_volume_size
  instance_profile             = module.iam.instance_profile
  env                          = var.env
  type                         = var.type
  key_name                     = var.key_name

}

# create key pair
module "key_pair" {
  source   = "./modules/key_pair"
  key_name = var.key_name
}

# create IAM resources
module "iam" {
  source = "./modules/iam"
}
