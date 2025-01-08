# Complete CI/CD with Terraform, GitHub Actions, and AWS

This project demonstrates a complete CI/CD pipeline using Terraform for AWS infrastructure and GitHub Actions for deployment. It includes a Node.js application containerized with Docker.

## Table of Contents

- [Project Overview](#project-overview)
- [Directory Structure](#directory-structure)
- [Key Components](#key-components)
- [Setup Instructions](#setup-instructions)
- [Deployment](#deployment)
- [Contributing](#contributing)

## Project Overview

This project automates the deployment of a Node.js application using Terraform to manage AWS infrastructure and GitHub Actions for continuous integration and deployment.

## Directory Structure

## Key Components

- **.github/workflows/deploy.yaml**: Defines the CI/CD pipeline using GitHub Actions to automatically build, test, and deploy the application upon pushes or pull requests.

- **node_app/**: Contains the Node.js application code.
  - **app.js**: The core of the application.
  - **Dockerfile**: Used to create a Docker image of the application for consistent deployment.
  - **package.json** and **package-lock.json**: Manage Node.js dependencies.

- **terraform/**: Contains the Infrastructure as Code (IaC) using Terraform.
  - **main.tf**: Defines the AWS infrastructure (e.g., VPC, EC2 instances, etc.).
  - **output.tf**: Declares output values from the Terraform deployment.
  - **variable.tf**: Defines input variables for the Terraform configuration.

- **.gitignore**: Specifies files and directories that Git should ignore (e.g., node_modules, .terraform).

- **README.md**: This file provides an overview of the project, instructions for setup and deployment, and other relevant information.

## Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/complete_cicd_with_terraform_and_aws.git
   cd complete_cicd_with_terraform_and_aws
   ```
2. **Install Dependencies**:
Navigate to the node_app directory and install Node.js dependencies:   This was done with the github action.
   ```bash
   cd node_app
   npm install   
   ```

## Configure AWS Credentials
The AWS credentials are configured in the Github environment to fufil GitSecOps.

## Deployment
- **GitHub Actions**: The deployment is automated using GitHub Actions. The workflow defined in .github/workflows/deploy.yaml will trigger on pushes or (pull requests - not yet implemented for PR).
Terraform: Use Terraform to manage and apply infrastructure changes:
   ```bash
   terraform plan \
            -var="region=$AWS_REGION" \
            -var="public_key=$PUBLIC_SSH_KEY" \
            -var="private_key=$PRIVATE_SSH_KEY" \
            -var="key_name=deployer_key" \
            -out=PLAN  
   ```
## Contributing
Contributions are welcome! Please fork the repository and submit a pull request for any improvements or bug fixes.



