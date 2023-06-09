<#
.Synopsis
Inventory for Azure RedHat OpenShift

.DESCRIPTION
This script consolidates information for all microsoft.redhatopenshift/openshiftclusters resource provider in $Resources variable. 
Excel Sheet Name: ARO

.Link
https://github.com/microsoft/ARI/Modules/Compute/ARO.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.2.0
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $ARO = $Resources | Where-Object { $_.TYPE -eq 'microsoft.redhatopenshift/openshiftclusters' }

    <######### Insert the resource Process here ########>

    if($ARO)
        {
            $tmp = @()
            foreach ($1 in $ARO) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                # Add ZoneRedundant "1, 2, 3" due it required by default
                $zones = "1, 2, 3"

                # Set Type value for combine tab
                $azureServices = 'Azure Red Hat OpenShift'

                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                   = $1.id;
                            'Subscription'         = $sub1.Name;
                            'Resource Group'       = $1.RESOURCEGROUP;
                            'Zones'                = $zones;
                            'Clusters'             = $1.NAME;
                            'Location'             = $1.LOCATION;
                            'Resource Name'              = $1.NAME;
                            'Azure Services'             = $azureServices;
                            'ARO Version'          = $data.clusterProfile.version;
                            'ARO Domain'           = $data.clusterProfile.domain;
                            'Outbound Type'        = $data.networkProfile.outboundType;
                            'Ingress Profile Name' = $data.ingressProfiles.name;
                            'Ingress Profile type' = $data.ingressProfiles.visibility;
                            'Ingress Profile IP'   = $data.ingressProfiles.ip;
                            'API Server type'      = $data.apiserverProfile.visibility;
                            'API Server URL'       = $data.apiserverProfile.url;
                            'API Server IP'        = $data.apiserverProfile.ip;
                            'Docker Pod Cidr'      = $data.networkProfile.podCidr;
                            'Service Cidr'         = $data.networkProfile.serviceCidr;
                            'Console URL'          = $data.consoleProfile.url;                   
                            'Master SKU'           = $data.masterProfile.vmSize;
                            'Master vNET'          = if($data.masterProfile.subnetId){$data.masterProfile.subnetId.split("/")[8]};
                            'Master Subnet'        = if($data.masterProfile.subnetId){$data.masterProfile.subnetId.split("/")[10]};                    
                            'Worker SKU'           = $data.workerProfiles.vmSize | Select-Object -Unique;        
                            'Worker DiskSize'      = $data.workerProfiles.diskSizeGB | Select-Object -Unique;        
                            'Total Worker Nodes'   = $data.workerProfiles.count;        
                            'Worker vNET'          = $data.workerProfiles.subnetId | ForEach-Object { $_.split("/")[8] } | Select-Object -Unique; 
                            'Worker Subnet'        = $data.workerProfiles.subnetId | ForEach-Object { $_.split("/")[10] } | Select-Object -Unique;       
                            'Resource U'           = $ResUCount;
                            'Tag Name'             = [string]$Tag.Name;
                            'Tag Value'            = [string]$Tag.Value
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }                
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.ARO) {

        $TableName = ('AROTable_'+($SmaResources.ARO.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Clusters')
        $Exc.Add('Zones')         
        $Exc.Add('Location')             
        $Exc.Add('ARO Version')          
        $Exc.Add('ARO Domain')           
        $Exc.Add('Outbound Type')        
        $Exc.Add('Ingress Profile Name')
        $Exc.Add('Ingress Profile type') 
        $Exc.Add('Ingress Profile IP')   
        $Exc.Add('API Server type')      
        $Exc.Add('API Server URL')       
        $Exc.Add('API Server IP')        
        $Exc.Add('Docker Pod Cidr')      
        $Exc.Add('Service Cidr')         
        $Exc.Add('Console URL')                
        $Exc.Add('Master SKU')           
        $Exc.Add('Master vNET')          
        $Exc.Add('Master Subnet')                     
        $Exc.Add('Worker SKU')           
        $Exc.Add('Worker DiskSize')        
        $Exc.Add('Total Worker Nodes')   
        $Exc.Add('Worker vNET')          
        $Exc.Add('Worker Subnet')
        if($InTag)
        {
            $Exc.Add('Tag Name')
            $Exc.Add('Tag Value') 
        }

        $ExcelVar = $SmaResources.ARO 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'ARO' -AutoSize -TableName $TableName -MaxAutoSizeRows 100 -TableStyle $tableStyle -Numberformat '0' -Style $Style
    

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