function Invoke-GenerateWixWxs
{
	Param([Parameter(Mandatory=$true)]
		  [string]$wxsFileName)

	$updateCode=[GUID]::NewGuid()
	$directoryName=(Get-Item -Path ".\" -Verbose).Name

	$exes=Get-ChildItem .\bin\Release | Where {$_.Name -Match 'exe$'} | Where {$_.Name -NotMatch 'vshost.exe$'} | Foreach { $_.Name }
	$dlls=Get-ChildItem .\bin\Release | Where {$_.Name -Match 'dll$'} | Foreach { $_.Name }
	$configs=Get-ChildItem .\bin\Release | Where {$_.Name -Match 'config$'} | Where {$_.Name -NotMatch 'vshost.exe.config$'} | Foreach { $_.Name }

$wxs=@"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="$directoryName.Msi" Language="1033" Version="1.0.0.0" Manufacturer="INTLFCStone" UpgradeCode="$updateCode">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perUser" InstallPrivileges="limited" />
    <MajorUpgrade Schedule="afterInstallInitialize" AllowDowngrades="yes" />
    <MediaTemplate EmbedCab="yes" />
    <Feature Id="ProductFeature" Title="$directoryName.Msi" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
      <ComponentRef Id="ProductLib" />
      <ComponentRef Id="ProductRoot" />
    </Feature>
    <Upgrade Id="$updateCode">
      <UpgradeVersion Property="REMOVINGTHEOLDVERSION" Minimum="1.0.0.0" RemoveFeatures="ALL" OnlyDetect="no" />
    </Upgrade>
  </Product>
  <Fragment>
    <SetProperty Id="ProgramFilesFolder" Value="[LocalAppDataFolder]" Before="CostFinalize"><![CDATA[NOT Privileged]]></SetProperty>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="Root" Name="INTL">
        <Directory Id="InstallFolder" Name="$directoryName.Msi" >
          <Directory Id="LibDirectory" Name="lib" />
        </Directory>
        </Directory>
      </Directory>
    </Directory>
    <DirectoryRef Id="RootDirectory">
      <Component Id="ProductRoot" Guid="$([GUID]::NewGuid())" KeyPath="yes">
      <CreateFolder />
      </Component>
    </DirectoryRef>
    <DirectoryRef Id="LibDirectory">
      <Component Id="ProductLib" Guid="$([GUID]::NewGuid())" KeyPath="yes">
        <CreateFolder />`n
"@


foreach ($dll in $dlls) {
$wxs +=@"
        <File Id="$directoryName.DLL.$dll" Source="..\$directoryName\bin\`$(var.Configuration)\$dll" />`n
"@
}

$wxs +=@"
      </Component>
    </DirectoryRef>
  </Fragment>
  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="InstallFolder">`n
"@
      foreach ($exe in $exes) {
$wxs +=@"
      <Component Id="$directoryName.Binaries.$exe" Guid="$([GUID]::NewGuid())">
        <File Id="$directoryName.Binaries.$exe" Source="..\$directoryName\bin\`$(var.Configuration)\$exe" />
      </Component>`n
"@
}
      foreach ($config in $configs) 
{
$wxs +=@"
      <Component Id="$directoryName.Config.$config" Guid="$([GUID]::NewGuid())">
        <File Id="$directoryName.Config.$config" Source="..\$directoryName\bin\`$(var.Configuration)\$config" />
      </Component>`n
"@
}
$wxs +=@"
    </ComponentGroup>
  </Fragment>
</Wix>`n
"@

	$path=".\bin\Release"

	if((Test-Path ".\bin\Debug"))
	{
		$path=".\bin\Debug"

		if (!(Test-Path "$path\$wxsFileName.wxs"))
		{
			New-Item "$path\$wxsFileName.wxs" -type file
		}

		Set-Content "$path\$wxsFileName.wxs" "$wxs"
	}

	if((Test-Path ".\bin\Release"))
	{
		$path=".\bin\Release"

		if (!(Test-Path "$path\$wxsFileName.wxs"))
		{
			New-Item "$path\$wxsFileName.wxs" -type file
		}

		Set-Content "$path\$wxsFileName.wxs" "$wxs"
	}
}

Export-ModuleMember -function Invoke-GenerateWixWxs
