set-strictmode -version latest

# change for your specific firewall context
$fwpolicyname = "fw-policy"
$rgname = "dmz-net-rg"
$rulecollectiongroupname = "FrontEndServices"
$rulecollectionname = "flazfe01-dnatrules"
$range = 10090..10100
$firewallpip = "20.103.40.41"
$serverip = "10.0.13.4"
$priority = 10000

## see https://learn.microsoft.com/en-us/azure/firewall/deploy-rules-powershell

# establish the context for the new rule

$policy = Get-AzFirewallPolicy -name $fwpolicyname -ResourceGroupName $rgname -verbose
$rulecollectiongroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $rulecollectiongroupname -AzureFirewallPolicy $policy -verbose
$existingrulecollection = $rulecollectiongroup.Properties.RuleCollection | where {$_.Name -eq $rulecollectionname}

# prepare the control channel rule

$rule = New-AzFirewallPolicyNatRule -Name "FTP-Control" -Description "FTP Passive Control Channel" -SourceAddress * -DestinationAddress $firewallpip -DestinationPort 21 -Protocol TCP -TranslatedAddress $serverip -TranslatedPort 21 -verbose
$existingrulecollection.Rules.Add($rule)

# prepare the data channel rules

$range |% {
	$rule = New-AzFirewallPolicyNatRule -Name "FTP-PassiveData-$_" -Description "FTP Passive Data port $_" -SourceAddress * -DestinationAddress $firewallpip -DestinationPort $_ -Protocol TCP -TranslatedAddress $serverip -TranslatedPort $_ -verbose
	# add the rule to the rule collection
	$existingrulecollection.Rules.Add($rule)
}

# update the rule collection on Azure

Set-AzFirewallPolicyRuleCollectionGroup -Name $rulecollectiongroupname -FirewallPolicyObject $policy -Priority $priority -RuleCollection $rulecollectiongroup.Properties.rulecollection -debug