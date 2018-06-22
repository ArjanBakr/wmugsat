break

$tenantName = 'Visual Studio Premium with MSDN'
$vmResourceGroupName = 'wmugsat-vm-rg01'
$opsResourceGroupName = 'wmugsat-ops-rg01'
$resourceGroupLocation = 'West Europe'
$deploymentName = 'ImageBuilder'
$keyvaultName = "wmugsat-kv-01"

Login-AzureRmAccount #-Credential $azureCredential

Get-AzureRmSubscription
Set-AzureRmContext -Subscription $tenantName

$subscriptionID = (Get-AzureRmContext).Subscription.Id

#Create resource group for Keyvault
New-AzureRmResourceGroup -Name $opsResourceGroupName -Location $resourceGroupLocation

#Create Keyvault
$vault = New-AzureRmKeyVault -VaultName $keyvaultName -ResourceGroupName $opsResourceGroupName -Location $resourceGroupLocation -EnabledForTemplateDeployment

#copy the Resource ID of the vault:
$vault.ResourceID
#<paste result of command here>

#add local admin password to keyvault
$adminUserName = 'wmugadm'
$adminCredential = Get-Credential -UserName $adminUsername -Message "Please enter the password for the Azure Admin user for the VM"
$adminPassword = $adminCredential.Password
#store Admin credentials in Keyvault
$secret = Set-AzureKeyVaultSecret -VaultName $keyvaultName -Name 'vmAdminPassword' -SecretValue $adminPassword

#change json file with correct keyvault location




#Deploy Virtual Machine
. .\deploy.ps1 -subscriptionId $subscriptionID -resourceGroupName $vmResourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName -keyVault $vault -adminName $adminUserName







