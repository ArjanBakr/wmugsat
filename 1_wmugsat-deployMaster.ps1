break

##STEP 1##

Set-ExecutionPolicy bypass -scope Process -Force
#Install-PackageProvider -Name NuGet -Force
#Install-module -Name AzureRM -verbose -force -AllowClobber
Install-module -Name AzureRM -verbose

#restart Virsoft Student VM first before continuing!
#Password is on PowerPoint Slide

$tenantName = 'Azure Lab'
$vmResourceGroupName = 'wmugsat-vm-rg01'
$opsResourceGroupName = 'wmugsat-ops-rg01'
$resourceGroupLocation = 'West Europe'
$deploymentName = 'ImageBuilder'
$keyvaultName = "wmugsat-kv-$(get-date -Format ddMMhhmmss)"

Login-AzureRmAccount

Get-AzureRmSubscription
Set-AzureRmContext -SubscriptionName $tenantName

$subscriptionID = (Get-AzureRmContext).Subscription.Id


##STEP 2##

#Create resource group for Keyvault
New-AzureRmResourceGroup -Name $opsResourceGroupName -Location $resourceGroupLocation

#Create Keyvault
$vault = New-AzureRmKeyVault -VaultName $keyvaultName -ResourceGroupName $opsResourceGroupName -Location $resourceGroupLocation -EnabledForTemplateDeployment

#add local admin password to keyvault
$adminUserName = 'wmugadm'
$adminCredential = Get-Credential -UserName $adminUsername -Message "Please enter the password for the Azure Admin user for the VM"
$adminPassword = $adminCredential.Password
#store Admin credentials in Keyvault
$secret = Set-AzureKeyVaultSecret -VaultName $keyvaultName -Name 'vmAdminPassword' -SecretValue $adminPassword


##STEP 3##

#Deploy Virtual Machine
. .\deploy.ps1 -subscriptionId $subscriptionID -resourceGroupName $vmResourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName -keyVault $vault -adminName $adminUserName







