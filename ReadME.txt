[1]Open run.ps1 script in the AzureCopy\TimerTrigger1\run.ps1 location and add values to the below parameters,
$ResourceGroup = "DemoAzureApp"
$StorageAccountName = "janaupworkapp"
$TableName = "officeemail"

[2]Compress-Archive .\AzureCopy\* -DestinationPath .\AzureCopy.zip

[3]Fill the values in App.json

[4] Execute the script
.\Deploy-AZFunction.ps1 -ConfigFile .\App.json