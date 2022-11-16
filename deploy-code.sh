# # Deploying infrastructure
cd infra-as-code
terraform apply -auto-approve

export VM_PUBLIC_IP=$(terraform output -raw server_public_ip)
export MYSQL_DB_HOST=$(terraform output -raw db_url)
export S3_BUCKET_ADDRESS=$(terraform output -raw s3_bucket_address)


# If needed to build docker images, left commented as it is already on docker hub.

# # Deploying backend
# cd ../backend
# docker build -t dig0w/letscode_be .
# docker push dig0w/letscode_be

# # Deploying frontend
# cd ../frontend
# docker build -t dig0w/letscode_fe . 
# docker push dig0w/letscode_fe