#Login to your Azure Subscription using az login before running the script
$AppServices = @(
az webapp list | ConvertFrom-Json
az functionapp list | ConvertFrom-Json
)
$VNetAppServices = foreach ($App in $AppServices) {    
    $Apps = az webapp vnet-integration list --n $App.Name -g $App.ResourceGroup
    if ($Apps -ne "[]") {
        $ServerFarm = $App.appServicePlanId -split '/'
        $VNetIntData = $Apps | ConvertFrom-Json
        $VNet = $VNetIntData.VnetResourceID -split '/'
        [PSCustomObject]@{
            AppServiceName = $App.Name
            ServerFarm     = $ServerFarm[8]
            ResourceGroup  = $App.ResourceGroup
            Location       = $App.Location
            VNetName       = $VNet[8]
            SubnetName     = $VNetIntData.name  
            VNetRG         = $VNet[4]       
        }
    }    
}
$VNetAppServices | ft