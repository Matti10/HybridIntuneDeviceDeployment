Checksum Generation
===========================================================================

Overview
--------

This document outlines the implementation of a checksum generation and validation system designed to ensure the integrity of files in a Git repository during deployment processes in Azure DevOps. The system utilizes PowerShell scripts to generate and validate checksums based on the contents of the repository.

This allows the intergrity of the data to be verified after its been downloaded

System Components
-----------------

The system comprises the following components:

1.  **PowerShell Functions**: Two key functions, `Build-CheckSum` and `Test-CheckSum`, perform the checksum generation and validation.
2.  **Azure DevOps Pipeline**: A YAML-based pipeline that triggers the execution of the PowerShell scripts whenever changes are pushed to the repository.

Checksum Overview
-----------------

A checksum is a unique string derived from the contents of a file or a collection of files. It serves as a fingerprint that can be used to verify that the files have not been altered. The system uses the MD5 hashing algorithm for generating checksums, which is efficient for detecting changes.

### Benefits of Using Checksums

-   **Integrity Verification**: Ensures that the files in the repository are unchanged and have not been corrupted.
-   **Change Detection**: Facilitates tracking changes made to files over time.
-   **Deployment Assurance**: Validates that the deployed files match the intended versions.

PowerShell Functions
--------------------

### 1\. `Build-CheckSum`

#### Purpose

Generates a checksum for all files in the specified directory and saves it to a designated file.

#### Parameters

-   `-checksumPath`: The path where the final checksum will be saved. Defaults to `.\checksum\checksum.txt`.
-   `-rootPath`: The root directory to start the checksum calculation. Defaults to the current directory (`.\`).

#### Example Usage

```powershell
Build-CheckSum -checksumPath ".\myChecksums.txt" -rootPath "C:\MyRepo"
```

#### Implementation

-   Retrieves all files in the specified directory and computes their MD5 checksums.
-   Combines individual checksums into a single checksum representing the entire repository.
-   Saves the final checksum to the specified file.

### 2\. `Test-CheckSum`

#### Purpose

Validates the current checksums of files in the specified directory against a previously saved checksum file.

#### Parameters

-   `-checksumPath`: The path of the file containing the expected checksum. Defaults to `.\checksum\checksum.txt`.
-   `-rootPath`: The root directory for checksum validation. Defaults to the current directory (`.\`).

#### Example Usage

```powershell
Test-CheckSum -checksumPath ".\myChecksums.txt" -rootPath "C:\MyRepo"
```

#### Implementation

-   Reads the saved checksum from the specified file.
-   Calls `Build-CheckSum` to compute the current checksum.
-   Compares the current checksum with the saved checksum and returns validation results.

Azure DevOps Pipeline Configuration
-----------------------------------

### YAML Pipeline Configuration

The pipeline is configured to trigger on every push to the repository. It uses the following YAML configuration:

```yaml
trigger:
  branches:
    include:
      - main  # or your desired branch

pool:
  vmImage: 'windows-latest'  # Use a Windows image for PowerShell

steps:
- checkout: self
  persistCredentials: true  # Allow Git push by reusing the pipeline's credentials

- powershell: |
    # Fetch all branches so that 'main' is available for checkout
    git fetch origin

    # Check out the correct branch (main) to avoid detached HEAD issues
    git checkout main

    # Include the checksum functions
    . .\checksum\checksum.ps1

    # Call the Build-CheckSum function to generate the checksum
    Build-CheckSum -checksumPath ".\checksum\checksum.txt"

    # Git add, commit, and push the checksum file back to the repo
    git config user.email "buildagent@tricare.com.au"
    git config user.name "Build Agent"
    
    git add .\checksum\checksum.txt
    git commit -m "Updated checksum file as part of pipeline"
    git push origin main  # Push back to the 'main' branch

  displayName: 'Generate and Push Checksum'

- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: '.\checksum\checksum.txt'
    artifactName: 'Checksum'
    publishLocation: 'Container'
```
### Pipeline Steps Explained

1.  **Checkout Code**: The pipeline checks out the repository code to the agent.
2.  **Generate Checksum**: The `Build-CheckSum` function is executed to create a checksum file for the repository.
3.  **Push Checksum to Branch**: Git is used to push the new Checksum to the checksum file in the repo

### DevOps Permissons
To facilitate this process, the build service needs permission to the branch. As such the account (Build\e9eb3174-eb9d-4d31-83de-74ac78ca6949) has been given the "GenericContribute" permissions can be managed for each repo here: https://tricare.visualstudio.com/TriCare%20PowerShell%20Library/_settings/repositories?repo=7ba9ed66-a7f2-42dc-b5a9-2ef74d4d6609&_a=permissionsMid

Conclusion
----------

The checksum generation and validation system provides a robust mechanism for ensuring the integrity of files in a Git repository during the development lifecycle. By utilizing PowerShell scripts within an Azure DevOps pipeline, the system automates the process of tracking changes and validating deployments, thereby enhancing the reliability of the development process.