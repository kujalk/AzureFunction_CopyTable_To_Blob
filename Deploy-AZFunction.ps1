<#
Purpose-
This script is used to deploy the Azure Function which is used to trigger when Resource Group cost exceeds

Resource that will deploy by this script
1. Azure Resource Group
2. Azure Storage Account
3. Azure App Function
4. "Contributor" role for App function

Developer - K.Janarthanan
Date - 23/11/2020
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $ConfigFile
)

try
{
    Import-Module -Name Az.Accounts -ErrorAction Stop
    Import-Module -Name Az.Resources -ErrorAction Stop
    
    $Config = Get-Content -Path $ConfigFile -ErrorAction Stop | ConvertFrom-Json
    
    Connect-AzAccount -Subscription $Config.SubscriptionName -Tenant $Config.TenantID

    $RGGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -eq $Config.ResourceGroup}

    if($RGGroup)
    {
        Write-Host "Resource Group found" -ForegroundColor Green
        
        #Create new Azure Function App
        Write-Host "Going to create Azure Function App" -ForegroundColor Green
        New-AzFunctionApp -Name $Config.FunctionAppName -ResourceGroupName $Config.ResourceGroup -Location $Config.Region -StorageAccount $Config.StorageAccountName -Runtime "PowerShell" -EA Stop | Out-Null
        Write-Host "Successfully created Azure Function App" -ForegroundColor Green

        #Assigning Permissions
        Write-Host "Going to assign role" -ForegroundColor Green
        Update-AzFunctionApp -Name $Config.FunctionAppName -ResourceGroupName $Config.ResourceGroup -IdentityType SystemAssigned -EA Stop | Out-Null
        $FuncApp = Get-AzFunctionApp -Name $Config.FunctionAppName -ResourceGroupName $Config.ResourceGroup -EA Stop
        New-AzRoleAssignment -RoleDefinitionName "Contributor" -ObjectId $FuncApp.IdentityPrincipalId -EA Stop | Out-Null
        Write-Host "Successfully assigned the role" -ForegroundColor Green
        
        if(Test-Path -Path $Config.FunctionPath)
        {
            Write-Host "Going to publish the function code" -ForegroundColor Green
            Publish-AzWebapp -ResourceGroupName $Config.ResourceGroup -Name $Config.FunctionAppName -ArchivePath $Config.FunctionPath -Confirm:$false -Force -EA Stop | Out-Null
            Write-Host "Successfully published the function code" -ForegroundColor Green
        }
        else 
        {
            throw "Zip folder not found"    
        }
    }
    else 
    {
        throw "Resource Group not found"    
    }
    Disconnect-AzAccount | Out-Null
}
catch
{
    Write-Host "Error Occured : $_`n" -ForegroundColor Red
    Disconnect-AzAccount
}