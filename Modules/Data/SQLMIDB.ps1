<#
.Synopsis
Inventory for Azure SQL Server

.DESCRIPTION
This script consolidates information for all microsoft.sql/servers resource provider in $Resources variable. 
Excel Sheet Name: SQL MI DBs

.Link
https://github.com/microsoft/ARI/Modules/Data/SQLSERVER.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.3.2
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle, $Unsupported) 

if ($Task -eq 'Processing') {

    $SQLSERVERMIDB = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/managedinstances/databases' }

    if($SQLSERVERMIDB)
        {
            $tmp = @()

            foreach ($1 in $SQLSERVERMIDB) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                $Tags = if(!!($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                $pvteps = if(!($data.privateEndpointConnections)) {[pscustomobject]@{id = 'NONE'}} else {$data.privateEndpointConnections | Select-Object @{Name="id";Expression={$_.id.split("/")[10]}}}
                
                # If $data.zoneRedundant is not null then it is a zone redundant database so generate output string "1, 2, 3"
                if ($data.zoneRedundant) {
                    $zonal = "1, 2, 3"
                } else { $zonal = ""}

                # Set Type value for combine tab
                $azureServices = 'Azure SQL Managed Instance'
                
                foreach ($pvtep in $pvteps) {
                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                    = $1.id;
                            'Subscription'          = $sub1.Name;
                            'Resource Group'             = $1.RESOURCEGROUP;
                            'MI parent'        = $1.id.split("/")[8];
                            'Name'                  = $1.NAME;
                            'Resource Name'              = $1.NAME;
                            'Azure Services'             = $azureServices;
                            'Collation'              = $data.collation;
                            'CreationDate'               = $data.creationDate;
                            'DefaultSecondaryLocation'               = $data.defaultSecondaryLocation;
                            'Status'           = $data.status;
                            'Tag Name'              = [string]$Tag.Name;
                            'Tag Value'             = [string]$Tag.Value
                            'Zones'                 = $zonal;
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }     
                }          
            }
            $tmp
        }
}
else {
    if ($SmaResources.SQLMIDB) {

        $TableName = ('SQLMIDBTable_'+($SmaResources.SQLMIDB.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range J:J
        $condtxt += New-ConditionalText FALSO -Range J:J
        $condtxt += New-ConditionalText FAUX -Range J:J
        $condtxt += New-ConditionalText offline -Range G:G

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('MI parent')
        $Exc.Add('Name')
        $Exc.Add('Zones')
        $Exc.Add('Collation')
        $Exc.Add('CreationDate')
        $Exc.Add('DefaultSecondaryLocation')
        $Exc.Add('Status')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.SQLMIDB

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL MI DBs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style


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


    }
}