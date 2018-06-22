<#
    .SYNOPSIS
    Deploys a template to Azure

    .DESCRIPTION
    Deploys an Azure Resource Manager template

    .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

    .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

    .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

    .PARAMETER deploymentName
    The deployment name.

    .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

    .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.

    .PARAMETER keyVault
    Required, Keyvault object.

    .PARAMETER keyVault
    Optional, Admin user account name.



#>

param(
  [Parameter(Mandatory=$True)]
  [string]
  $subscriptionId,

  [Parameter(Mandatory=$True)]
  [string]
  $resourceGroupName,

  [string]
  $resourceGroupLocation,

  [Parameter(Mandatory=$True)]
  [string]
  $deploymentName,

  [string]
  $templateFilePath = "template.json",

  [string]
  $parametersFilePath = "parameters.json",

  [Parameter(Mandatory=$True)]
  $keyVault,

  [string]
  $adminName = "wmugadmin"

)

<#
    .SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
#Write-Host "Logging in...";
#Login-AzureRmAccount;

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.devtestlab","microsoft.network");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

$vmName = "ImageBuilder"
$adminUserName = $adminName
$vault = $keyVault
$adminSecret = Get-AzureKeyVaultSecret -VaultName $vault.VaultName -Name 'vmAdminPassword'
$adminPassword = ($adminSecret.SecretValueText | ConvertTo-SecureString -AsPlainText -Force)

$params = [ordered]@{
    virtualMachineName = $vmName;
    virtualMachineSize = "Standard_D4s_v3";
    adminUsername = $adminUserName;
    virtualNetworkName = "$vmName-vnet";
    networkInterfaceName = "$vmName-nic01";
    networkSecurityGroupName = "$vmName-nsg";
    addressPrefix = "10.1.0.0/24";
    subnetName = "default";
    subnetPrefix = "10.1.0.0/24";
    publicIpAddressName = "$vmName-pip";
    publicIpAddressType = "Dynamic";
    publicIpAddressSku = "Basic";
    autoShutdownStatus = "Enabled";
    autoShutdownTime = "17:00";
    autoShutdownTimeZone = "W. Europe Standard Time";
    autoShutdownNotificationStatus = "Disabled";
    location = "westeurope";
    networkResourceGroupName = $resourceGroupName;
}

$params.Add("adminPassword", $adminPassword)

#resourceGroupName = $resourceGroupName;

Write-Host "Starting deployment...";

try {
    $Deployment = New-AzureRmResourceGroupDeployment `
        -Name                        $deploymentName `
        -ResourceGroupName           $resourceGroupName `
        -TemplateFile                $templateFilePath `
        -TemplateParameterObject     $params `
        -Mode                        incremental `
        -Force `
        -Verbose
} catch { throw $_ }



# Start the deployment
#Write-Host "Starting deployment...";
#if(Test-Path $parametersFilePath) {
#    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
#} else {
#    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;
#}