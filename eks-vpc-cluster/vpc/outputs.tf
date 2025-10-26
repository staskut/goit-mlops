output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
 value    = [aws_subnet.public.id, aws_subnet.public2.id]
 description = "Public subnet IDs"
}

output "private_subnets" {
 value    = [aws_subnet.private.id, aws_subnet.private2.id]
 description = "Private subnet IDs"
}