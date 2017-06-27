function Invoke-GenerateWixWxs
{
	Param([Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
		  [string]$WxsFileName,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [ValidateSet('Debug', 'Release')]
          [String]$Configuration,
		  [Parameter(Mandatory = $true)]
          [bool]$HasIcon,
          [Parameter(Mandatory = $true)]
          [bool]$MoveWxsFile)

	$updateCode=[GUID]::NewGuid()
	$directoryName=(Get-Item -Path ".\" -Verbose).Name

    $path=""
    switch ($Configuration) 
    { 
        Debug {$path=".\bin\Debug"} 
        Release {$path=".\bin\Release"} 
    }

    if(!(Test-Path $path))
	{
        Write-Host "Path $path does not exist."
        return; 
	}

	$exes=Get-ChildItem $path | Where {$_.Name -Match 'exe$'} | Where {$_.Name -NotMatch 'vshost.exe$'} | Foreach { $_.Name }
	$dlls=Get-ChildItem $path | Where {$_.Name -Match 'dll$'} | Foreach { $_.Name }
	$configs=Get-ChildItem $path | Where {$_.Name -Match 'config$'} | Where {$_.Name -NotMatch 'vshost.exe.config$'} | Foreach { $_.Name }

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
	  <ComponentRef Id="ApplicationShortcut" />
      <ComponentRef Id="ApplicationShortcutDesktop" />
    </Feature>
    <Upgrade Id="$updateCode">
      <UpgradeVersion Property="REMOVINGTHEOLDVERSION" Minimum="1.0.0.0" RemoveFeatures="ALL" OnlyDetect="no" />
    </Upgrade>
  </Product>
  <Fragment>
    <SetProperty Id="ProgramFilesFolder" Value="[LocalAppDataFolder]" Before="CostFinalize"><![CDATA[NOT Privileged]]></SetProperty>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="RootDirectory" Name="INTL">
        <Directory Id="InstallFolder" Name="$directoryName.Msi" >
          <Directory Id="LibDirectory" Name="lib" />
        </Directory>
        </Directory>
      </Directory>
	        <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="$directoryName" />
      </Directory>
      <Directory Id="DesktopFolder" Name="Desktop"/>
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
    </DirectoryRef>`n
"@	

    if($HasIcon)
    {
$wxs+=@"
	<Icon Id="$directoryName.ico" SourceFile="..\$directoryName\bin\`$(var.Configuration)\$directoryName.ico" />
	<DirectoryRef Id="ApplicationProgramsFolder">
     <Component Id="ApplicationShortcut" Guid="$([GUID]::NewGuid())">
       <Shortcut Id="ApplicationStartMenuShortcut" Icon="$directoryName.ico" Name="$directoryName.Msi" Description="$directoryName.Msi" Target="[InstallFolder]$directoryName.exe" WorkingDirectory="InstallFolder" />
       <RemoveFolder Id="RemoveApplicationProgramsFolder" Directory="ApplicationProgramsFolder" On="uninstall" />
       <RegistryValue Root="HKCU" Key="Software\INTLFCStone\$directoryName.Msi" Name="installed" Type="integer" Value="1" KeyPath="yes" />
     </Component>
   </DirectoryRef>
   <DirectoryRef Id="DesktopFolder">
     <Component Id="ApplicationShortcutDesktop" Guid="$([GUID]::NewGuid())">
       <Shortcut Id="ApplicationDesktopShortcut" Icon="$directoryName.ico" Name="$directoryName.Msi" Description="$directoryName.Msi>" Target="[InstallFolder]$directoryName.exe" WorkingDirectory="InstallFolder" />
       <RemoveFolder Id="RemoveDesktopFolder" Directory="DesktopFolder" On="uninstall" />
       <RegistryValue Root="HKCU" Key="Software\INTLFCStone\I$directoryName.Msi" Name="installed" Type="integer" Value="1" KeyPath="yes" />
     </Component>
   </DirectoryRef>
	
  </Fragment>
  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="InstallFolder">`n
"@
	}
	else
	{
$wxs+=@"    
<DirectoryRef Id="ApplicationProgramsFolder">
     <Component Id="ApplicationShortcut" Guid="$([GUID]::NewGuid())">
       <Shortcut Id="ApplicationStartMenuShortcut" Name="$directoryName.Msi" Description="$directoryName.Msi" Target="[InstallFolder]$directoryName.exe" WorkingDirectory="InstallFolder" />
       <RemoveFolder Id="RemoveApplicationProgramsFolder" Directory="ApplicationProgramsFolder" On="uninstall" />
       <RegistryValue Root="HKCU" Key="Software\INTLFCStone\$directoryName.Msi" Name="installed" Type="integer" Value="1" KeyPath="yes" />
     </Component>
   </DirectoryRef>
   <DirectoryRef Id="DesktopFolder">
     <Component Id="ApplicationShortcutDesktop" Guid="$([GUID]::NewGuid())">
       <Shortcut Id="ApplicationDesktopShortcut" Name="$directoryName.Msi" Description="$directoryName.Msi>" Target="[InstallFolder]$directoryName.exe" WorkingDirectory="InstallFolder" />
       <RemoveFolder Id="RemoveDesktopFolder" Directory="DesktopFolder" On="uninstall" />
       <RegistryValue Root="HKCU" Key="Software\INTLFCStone\I$directoryName.Msi" Name="installed" Type="integer" Value="1" KeyPath="yes" />
     </Component>
   </DirectoryRef>
	
  </Fragment>
  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="InstallFolder">`n
"@
	}

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

	if (!(Test-Path "$path\$wxsFileName.wxs"))
	{
		New-Item "$path\$wxsFileName.wxs" -type file
	}

	Set-Content "$path\$wxsFileName.wxs" "$wxs"

    if($MoveWxsFile)
    {
        Move-Item "$path\$wxsFileName.wxs" "..\$directoryName.Msi\"
    }

}

Export-ModuleMember -function Invoke-GenerateWixWxs
