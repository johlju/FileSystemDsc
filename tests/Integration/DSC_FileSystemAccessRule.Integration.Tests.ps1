$script:dscModuleName = 'FileSystemDsc'
$script:dscResourceFriendlyName = 'FileSystemAccessRule'
$script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

try
{
    Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

function Wait-ForIdleLcm
{
    [CmdletBinding()]
    param ()

    while ((Get-DscLocalConfigurationManager).LCMState -ne 'Idle')
    {
        Write-Verbose -Message 'Waiting for the LCM to become idle'

        Start-Sleep -Seconds 2
    }
}

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"

            $mockFolderPath1 = Join-Path -Path $TestDrive -ChildPath 'SampleFolder1'
            $mockFolderPath2 = Join-Path -Path $TestDrive -ChildPath 'SampleFolder2'
            $mockFolderPath3 = Join-Path -Path $TestDrive -ChildPath 'SampleFolder3'

            New-Item -Path $mockFolderPath1 -ItemType 'Directory' -Force
            New-Item -Path $mockFolderPath2 -ItemType 'Directory' -Force
            New-Item -Path $mockFolderPath3 -ItemType 'Directory' -Force

            $ConfigurationData.AllNodes[0]['Path1'] = $mockFolderPath1
            $ConfigurationData.AllNodes[0]['Path2'] = $mockFolderPath2
            $ConfigurationData.AllNodes[0]['Path3'] = $mockFolderPath3
        }

        $configurationName = "$($script:dscResourceName)_Prerequisites_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_NewRulePath1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.Path1
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.UserName
                $resourceCurrentState.Rights | Should -Contain 'Read'
                $resourceCurrentState.Rights | Should -Contain 'Synchronize'
                $resourceCurrentState.IsActiveNode | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_NewRulePath2_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.Path2
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.LocalGroupName1
                $resourceCurrentState.Rights | Should -Contain 'Modify'
                $resourceCurrentState.Rights | Should -Contain 'Synchronize'
                $resourceCurrentState.IsActiveNode | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_NewRulePath3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.Path3
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.LocalGroupName2
                $resourceCurrentState.Rights | Should -Contain 'Read'
                $resourceCurrentState.Rights | Should -Contain 'Synchronize'
                $resourceCurrentState.IsActiveNode | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_UpdateRulePath1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path  | Should -Be $ConfigurationData.AllNodes.Path1
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.UserName
                $resourceCurrentState.Rights | Should -Not -Contain 'Read'
                $resourceCurrentState.Rights | Should -Contain 'Synchronize'
                $resourceCurrentState.Rights | Should -Contain 'Write'
                $resourceCurrentState.IsActiveNode  | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_UpdateRulePath3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path  | Should -Be $ConfigurationData.AllNodes.Path3
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.LocalGroupName2
                $resourceCurrentState.Rights | Should -Not -Contain 'Read'
                $resourceCurrentState.Rights | Should -Not -Contain 'Synchronize'
                $resourceCurrentState.Rights | Should -Contain 'FullControl'
                $resourceCurrentState.IsActiveNode  | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_RemoveRulePath1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Absent'
                $resourceCurrentState.Path  | Should -Be $ConfigurationData.AllNodes.Path1
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.UserName
                $resourceCurrentState.Rights | Should -BeNullOrEmpty
                $resourceCurrentState.IsActiveNode  | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_RemoveRulePath2_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path  | Should -Be $ConfigurationData.AllNodes.Path2
                $resourceCurrentState.Identity | Should -Be $ConfigurationData.ALlNodes.LocalGroupName1
                Write-Verbose -Message ($resourceCurrentState.Rights | Out-String) -Verbose
                $resourceCurrentState.Rights | Should -Not -Contain 'Write'
                $resourceCurrentState.Rights | Should -Not -Contain 'Modify'
                $resourceCurrentState.Rights | Should -Contain 'Delete'
                $resourceCurrentState.Rights | Should -Contain 'ReadAndExecute'
                $resourceCurrentState.Rights | Should -Contain 'Synchronize'
                $resourceCurrentState.IsActiveNode  | Should -BeTrue
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_Cleanup_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# # Basic integration tests setup
# try
# {
#     $cleanupTestIdentity = $true
#     #region SETUP
#     $testIdentity = "xFSAR_Test"

#     $foundGroup = Get-LocalGroup -Name $testIdentity -ErrorAction SilentlyContinue
#     if (-not $foundGroup)
#     {
#         # create an empty local group if it doesn't already exist,
#         # which we will be assigning permissions to a temp folder to in these tests.
#         try
#         {
#             Write-Verbose -Verbose "Trying to create local group '$testIdentity'"
#             New-LocalGroup -Description "Group for DSC_FileSystemAccessRule tests" -Name $testIdentity -ErrorAction 'Stop'
#         }
#         catch
#         {
#             if ($_ -like "*Access denied.*")
#             {
#                 # Attempt to use an arbitrary existing group
#                 $cleanupTestIdentity = $false
#                 $testIdentity = 'Users'
#                 Write-Warning "Couldn't create a temporary local group. Instead using '$testIdentity'"
#                 Write-Verbose -Verbose "Using testIdentity '$testIdentity'"
#             }
#             else
#             {
#                 throw "Need to run as administrator"
#             }
#         }
#     }
#     #endregion SETUP

#     Import-Module -Name "$PSScriptRoot\..\..\output\FileSystemDsc\*\DSCResources\DSC_FileSystemAccessRule\DSC_FileSystemAccessRule.psm1"

#     Describe "DSC_FileSystemAccessRule Functional unit tests" {
#         Context "Test-TargetResource when ACL is absent" {
#             BeforeAll {
#                 $testRoot = "$TestDrive\xFSAR_TestFolder"
#                 New-Item $testRoot -ItemType Directory -Force -ErrorAction 'Stop'
#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @() -Ensure Absent

#                 # Shouldn't throw when run twice, not necessary for DSC but just verifying my test setup is safe
#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @() -Ensure Absent
#             }

#             $absentAclTestCases = @(
#                 @{
#                     Rights         = @()
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for nothing absent should succeed as nothing should be present currently"
#                 },
#                 @{
#                     Rights         = @("Write")
#                     Ensure         = 'Present'
#                     ExpectedResult = $false
#                     Explanation    = "Permissions should have been removed"
#                 },
#                 @{
#                     Rights         = @("Write", "Read")
#                     Ensure         = 'Present'
#                     ExpectedResult = $false
#                     Explanation    = "Permissions should have been removed"
#                 },
#                 @{
#                     Rights         = @("Write", "Read")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permissions should have been removed"
#                 },
#                 @{
#                     Rights         = @("Synchronize")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permissions should have been removed"
#                 },
#                 @{
#                     Rights         = @("Read")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permissions should have been removed"
#                 }
#             )

#             It 'Returns <ExpectedResult> for Ensure <Ensure> and Rights <Rights> with no existing rights' -TestCases $absentAclTestCases {
#                 Param(
#                     $Ensure,
#                     $Rights,
#                     $ExpectedResult,
#                     $Explanation
#                 )
#                 $result = Test-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights $Rights -Ensure $Ensure
#                 $result | Should -Be $ExpectedResult -Because $Explanation
#             }
#         }


#         Context "Set and Test when multiple permissions including a subset is applied" {
#             BeforeAll {
#                 $testRoot = "$TestDrive\xFSAR_TestFolder"
#                 New-Item $testRoot -ItemType Directory -Force -ErrorAction 'Stop'
#                 # This should effectively end up as 'Write, ReadAndExecute'
#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @("Write", "Read", "ExecuteFile") -Ensure Present
#             }
#             $setSubsetReadAndExecuteTests = @(
#                 @{
#                     Rights         = @("Write")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for write should be added"
#                 },
#                 @{
#                     Rights         = @("Read")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for read should be added"
#                 },
#                 @{
#                     Rights         = @("ReadAndExecute")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for ReadAndExecute should be added and supported via Flags"
#                 },
#                 @{
#                     Rights         = @("FullControl")
#                     Ensure         = 'Present'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for FullControl should NOT exist yet"
#                 },
#                 @{
#                     Rights         = @("FullControl")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for FullControl should NOT be considered to be on the object for the absent so test should pass"
#                 }
#             )
#             It 'Returns <ExpectedResult> for Ensure <Ensure> and Rights <Rights> with combined multi-rights' -TestCases $setSubsetReadAndExecuteTests {
#                 Param(
#                     $Ensure,
#                     $Rights,
#                     $ExpectedResult,
#                     $Explanation
#                 )
#                 $result = Test-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights $Rights -Ensure $Ensure
#                 $result | Should -Be $ExpectedResult -Because $Explanation
#             }
#         }

#         Context "Set and Test subsets of a big permission like FullControl" {
#             BeforeAll {
#                 $testRoot = "$TestDrive\xFSAR_TestFolder"
#                 New-Item $testRoot -ItemType Directory -Force -ErrorAction 'Stop'
#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @("FullControl") -Ensure Present
#             }
#             $fullControlSubsetTests = @(
#                 @{
#                     Rights         = @("FullControl")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for FullControl should be added now"
#                 },
#                 @{
#                     Rights         = @("FullControl")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for FullControl absent should fail"
#                 },
#                 @{
#                     Rights         = @("Modify")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Modify absent should fail as it is encompassed in FullControl"
#                 },
#                 @{
#                     Rights         = @("Modify")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for Modify true should succeed as it is encompassed in FullControl"
#                 },
#                 @{
#                     Rights         = @("Read")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Read absent should fail as it is encompassed in FullControl"
#                 },
#                 @{
#                     Rights         = @("Read", "Write")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Read and Write absent should fail as both is encompassed in FullControl"
#                 },
#                 @{
#                     Rights         = @("Read", "Write")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for Read and Write present should succeed as both are encompassed in FullControl"
#                 },
#                 @{
#                     Rights         = @("Read", "Write", "ExecuteFile")
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for Read and Write absent should fail as both is encompassed in FullControl"
#                 }
#             )
#             It 'Returns <ExpectedResult> for Ensure <Ensure> and Rights <Rights> with FullControl existing rights' -TestCases $fullControlSubsetTests {
#                 Param(
#                     $Ensure,
#                     $Rights,
#                     $ExpectedResult,
#                     $Explanation
#                 )
#                 $result = Test-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights $Rights -Ensure $Ensure
#                 $result | Should -Be $ExpectedResult -Because $Explanation
#             }
#         }

#         Context "Set and Test against an existing multi-flag permission: Read, Write" {
#             BeforeAll {
#                 $testRoot = "$TestDrive\xFSAR_TestFolder"
#                 New-Item $testRoot -ItemType Directory -Force -ErrorAction 'Stop'
#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @() -Ensure Absent

#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @("Read", "Write") -Ensure Present
#             }

#             $existingMultiPermission = @(
#                 @{
#                     Rights         = @()
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for nothing absent should fail as there are permissions to remove currently"
#                 },
#                 @{
#                     Rights         = @("Read", "Write")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Read and Write absent should fail as both are present"
#                 },
#                 @{
#                     Rights         = @("Read", "FullControl")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Read and FullControl absent should fail as Read is present currently even though FullControl is not"
#                 },
#                 @{
#                     Rights         = @('Read')
#                     Ensure         = 'Absent'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Read absent should fail as Read is present currently"
#                 },
#                 @{
#                     Rights         = @('Read')
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission Read is present currently"
#                 },
#                 @{
#                     Rights         = @('Write')
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission Write is present currently"
#                 },
#                 @{
#                     Rights         = @('Read', 'Write')
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission Read and Write are present currently"
#                 },
#                 @{
#                     Rights         = @('Synchronize')
#                     Ensure         = 'Present'
#                     ExpectedResult = $true
#                     Explanation    = "Permission Read should have applied Synchronize automatically by the operating system"
#                 }
#             )
#             It 'Returns <ExpectedResult> for Ensure <Ensure> and Rights <Rights> with Read, Write existing rights' -TestCases $existingMultiPermission {
#                 Param(
#                     $Ensure,
#                     $Rights,
#                     $ExpectedResult,
#                     $Explanation
#                 )
#                 $result = Test-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights $Rights -Ensure $Ensure
#                 $result | Should -Be $ExpectedResult -Because $Explanation
#             }
#         }

#         Context "Set and Test against a non-existant user" {
#             BeforeAll {
#                 $testRoot = "$TestDrive\xFSAR_TestFolder"
#                 New-Item $testRoot -ItemType Directory -Force -ErrorAction 'Stop'
#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @() -Ensure Absent

#                 Set-TargetResource -Verbose -Path "$testRoot" -Identity $testIdentity -Rights @("Read", "Write") -Ensure Present
#             }

#             $nonExistantUserPermission = @(
#                 @{
#                     Rights         = @()
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for unspecified absent on something with no ACLs should succeed"
#                     Identity       = "Fake"
#                 },
#                 @{
#                     Rights         = @("Write")
#                     Ensure         = 'Absent'
#                     ExpectedResult = $true
#                     Explanation    = "Permission for Write absent on something with no ACLs should succeed"
#                     Identity       = "Fake"
#                 },
#                 @{
#                     Rights         = @("Read")
#                     Ensure         = 'Present'
#                     ExpectedResult = $false
#                     Explanation    = "Permission for Read present on something that doesn't exist should not pass"
#                     Identity       = "Fake"
#                 }
#             )
#             It 'Returns <ExpectedResult> for Ensure <Ensure> and Rights <Rights> for a non-existent identity' -TestCases $nonExistantUserPermission {
#                 Param(
#                     $Ensure,
#                     $Rights,
#                     $ExpectedResult,
#                     $Explanation,
#                     $Identity
#                 )
#                 $result = Test-TargetResource -Verbose -Path "$testRoot" -Identity $Identity -Rights $Rights -Ensure $Ensure
#                 $result | Should -Be $ExpectedResult -Because $Explanation
#             }
#         }
#     }
# }
# finally
# {
#     if ($cleanupTestIdentity)
#     {
#         Get-LocalGroup $testIdentity -ErrorAction 'SilentlyContinue' | Remove-LocalGroup -ErrorAction 'Stop'
#     }
# }
