function Get-APBranchCheckBody
{
    <#
    .SYNOPSIS

    Return body part of branch check call.

    .DESCRIPTION

    Return body part of branch check call.

    .PARAMETER Resource

    Object resource to apply barcnh check, like ServiceEndpoint or Environment.

    .PARAMETER TimeoutDays

    The number of days before the approval times out.

    .PARAMETER BranchFilter

    The branch filter to be applied.

    .PARAMETER EnsureProtectionOfBranch

    Check that branch is protected. Default should be $false

    .INPUTS
    
    None, does not support pipeline.

    .OUTPUTS

    PSObject, Azure Pipelines environment.

    .EXAMPLE

    $resource = @{
                type = 'environment'
                id   = apEnvironment.Id
                name = apEnvironment.Name
            }
    or
    $resource = @{
                type = 'endpoint'
                id   = $apServiceEndpoint.Id
                name = $apServiceEndpoint.Name
            }

    Get-APBranchCheckBody -Resource $resource -TimeoutDays 3 -BranchFilter "master,refs/heads/master" -EnsureProtectionOfBranch $false

    .LINK

    Undocumented at the time this was created.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [object]
        $Resource,

        [Parameter(Mandatory)]
        [ValidateRange(1, 30)]
        [string]
        $TimeoutDays, 

        [Parameter()]
        [string]
        $BranchFilter,

        [Parameter()]
        [bool]
        $EnsureProtectionOfBranch
    )

    begin
    {
    }
        
    process
    {
        $body = @{
            settings = @{
                displayName = "Branch control"
                definitionRef = @{
                    id = "86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b"
                    name = "evaluatebranchProtection"
                    version = "0.0.1"
                }
                inputs = @{
                    allowedBranches = $BranchFilter
                    ensureProtectionOfBranch = $EnsureProtectionOfBranch.ToString().ToLower()
                }
                retryInterval = 5
            }
            type     = @{
                name = 'Task Check'
                id   = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'
            }
            resource = $Resource
            timeout  = (New-TimeSpan -Days $TimeoutDays).TotalMinutes
        }

        Return $body
    }

    end
    {
    }
}