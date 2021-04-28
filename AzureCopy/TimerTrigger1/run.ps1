param($Timer)

try 
{
    $ResourceGroup = "DemoAzureApp"
    $StorageAccountName = "janaupworkapp"
    $TableName = "officeemail"

    $ResourceGP = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -eq $ResourceGroup} 

    if($ResourceGP)
    {
        $ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName -EA Stop).context
        $cloudTable = (Get-AzStorageTable -Name $TableName -Context $ctx -EA Stop).CloudTable

        $TableData = Get-AzTableRow -table $cloudTable -ErrorAction Stop
        $PartitionKey = $TableData.PartitionKey | select -Unique

        if(-not $PartitionKey)
        {
            Write-Host "No any partition key found"
        }
        
        foreach($Item in $PartitionKey)
        {
            Write-Host "`nWorking on partitionkey - $Item" -ForegroundColor Green
            $CSV_File = ("{0}.csv" -f $Item)

            $FilterData = $TableData | Where-Object{$_.PartitionKey -eq $Item}
            $FilterData | Export-Csv -NoTypeInformation -Path $CSV_File

            if(Test-Path -Path $CSV_File -PathType Leaf)
            {
                Write-Host "Uploading file $CSV_File to blobstorage" -ForegroundColor Green
                Set-AzStorageBlobContent -File $CSV_File -Container "officecsv" -Blob $CSV_File -Context $ctx -Force -ErrorAction Stop | Out-Null
            } 
            else 
            {
                Write-Host "CSV file $CSV_File not found" -ForegroundColor Yellow    
            }      
        }
        
        Write-Host "`nDone with the script" -ForegroundColor Green
    }
    else 
    {
        Write-Host "No resource group found" -ForegroundColor Green
    }
   
}
catch 
{
    Write-Host "Error - $_" -ForegroundColor Red
}