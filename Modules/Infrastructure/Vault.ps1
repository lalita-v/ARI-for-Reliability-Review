﻿<#
.Synopsis
Inventory for Azure Storage Account

.DESCRIPTION
This script consolidates information for all microsoft.keyvault/vaults and  resource provider in $Resources variable. 
Excel Sheet Name: Vault

.Link
https://github.com/microsoft/ARI/Modules/Infrastructure/Vault.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.2.1
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Unsupported)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $VAULT = $Resources | Where-Object {$_.TYPE -eq 'microsoft.keyvault/vaults'}

    <######### Insert the resource Process here ########>

    if($VAULT)
        {
            $tmp = @()

            foreach ($1 in $VAULT) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if([string]::IsNullOrEmpty($Data.enableSoftDelete)){$Soft = $false}else{$Soft = $Data.enableSoftDelete}
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                # Add ZoneRedundant "Zone Redundant" due it required by default
                 $zones = "Zone Redundant"

                # Load Get-Service Detail Module
                . ./Get-ServiceDetails.ps1

                # Due Vault is Global, only get data to display report by Private Endpoint
                
                #$Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                
                # If $privateLinkCount is greater than 0, then assign AzureKeyVault-Private to $jsonOutput
                # Else, assign AzureKeyVault to $jsonOutput
                if ($data.privateEndpointConnections.Count -gt 0) {
                    $jsonOutput = Get-ServiceDetails -Type 'AzureKeyVault-Private' -Resilience 'Global'
                } else {
                    $jsonOutput = Get-ServiceDetails -Type "AzureKeyVault" -Resilience 'Global'
                }
                
                # Get RTO information from $jsonOutput field RTO
                $RTO = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty RTO

                # Get RPO information from $jsonOutput field RPO
                $RPO = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty RPO
                
                # Get SLA information from $jsonOutput field SLA
                $SLA = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty SLA

                # Set Type value for combine tab
                $azureServices = 'Azure Keyvault'

                Foreach($2 in $data.accessPolicies)
                    {
                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                         = $1.id;
                            'Subscription'               = $sub1.Name;
                            'Resource Group'             = $1.RESOURCEGROUP;
                            'Name'                       = $1.NAME;
                            'Zones'                      = $zones;
                            'Location'                  = $1.LOCATION;
                            'Resource Name'              = $1.NAME;
                            'Azure Services'             = $azureServices;
                            'RTO'                           = [string]$RTO;
                            'RPO'                           = [string]$RPO;
                            'SLA'                           = [string]$SLA;  
                            'SKU Family'                 = $data.sku.family;
                            'SKU'                        = $data.sku.name;
                            'Vault Uri'                  = $data.vaultUri;
                            'Enable RBAC'                = $data.enableRbacAuthorization;
                            'Enable Soft Delete'         = $Soft;
                            'Enable for Disk Encryption' = $data.enabledForDiskEncryption;
                            'Enable for Template Deploy' = $data.enabledForTemplateDeployment;
                            'Soft Delete Retention Days' = $data.softDeleteRetentionInDays;
                            'Certificate Permissions'    = [string]$2.permissions.certificates | ForEach-Object {$_ + ', '};
                            'Key Permissions'            = [string]$2.permissions.keys | ForEach-Object {$_ + ', '};
                            'Secret Permissions'         = [string]$2.permissions.secrets | ForEach-Object {$_ + ', '} ;
                            'Resource U'                 = $ResUCount;
                            'Tag Name'                   = [string]$Tag.Name;
                            'Tag Value'                  = [string]$Tag.Value
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                        }
                    }               
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.Vault)
    {

        $TableName = ('VaultTable_'+($SmaResources.Vault.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $condtxt = @()
        $condtxt += New-ConditionalText false -Range I:I
        $condtxt += New-ConditionalText falso -Range I:I

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Zones')
        $Exc.Add('Location')
        $Exc.Add('SKU Family')
        $Exc.Add('SKU')
        $Exc.Add('Vault Uri')
        $Exc.Add('Enable RBAC')
        $Exc.Add('Enable Soft Delete')
        $Exc.Add('Enable for Disk Encryption')
        $Exc.Add('Enable for Template Deploy')
        $Exc.Add('Soft Delete Retention Days')
        $Exc.Add('Certificate Permissions')
        $Exc.Add('Key Permissions')
        $Exc.Add('Secret Permissions')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.Vault 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Key Vaults' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

        ## Export to Combine Tab

        ## Create New ExcCombine Object by copy from $Exc from selected column Subscription, Resource Group, VM Name, Zone 
        $ExcCombine = New-Object System.Collections.Generic.List[System.Object]
        $ExcCombine.Add('Subscription')
        $ExcCombine.Add('Resource Group')
        $ExcCombine.Add('Azure Services')
        $ExcCombine.Add('Resource Name')
        $ExcCombine.Add('Zones')
        $ExcCombine.Add('Location')

        # # Export-Excel with No Table in the worksheet ResourcesCombine
        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $ExcCombine | 
        Export-Excel -Path $File -WorksheetName 'Combine'  -MaxAutoSizeRows 100  -Style $Style, $StyleExt  -Append


        <######## Insert Column comments and documentations here following this model #########>


        #$excel = Open-ExcelPackage -Path $File -KillExcel


        #Close-ExcelPackage $excel 

    }
}