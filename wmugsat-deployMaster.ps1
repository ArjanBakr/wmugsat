break

$tenantName = 'Visual Studio Premium with MSDN'
$resourceGroupName = 'WMUGSaturday-ImageBuilder'
$resourceGroupLocation = 'West Europe'
$deploymentName = 'ImageBuilder'

Login-AzureRmAccount #-Credential $azureCredential

Get-AzureRmSubscription
Set-AzureRmContext -Subscription $tenantName

$subscriptionID = (Get-AzureRmContext).Subscription.Id

. .\deploy.ps1 -subscriptionId $subscriptionID -resourceGroupName $resourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName







