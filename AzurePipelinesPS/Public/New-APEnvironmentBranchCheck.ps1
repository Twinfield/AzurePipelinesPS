function New-APEnvironmentBranchCheck
{
    <#
    .SYNOPSIS

    Creates an Azure Pipeline environment branch check.

    .DESCRIPTION

    Creates an Azure Pipeline environment branch check based on environment id.
    The id can be retrieved with Get-APEnvironment.

    .PARAMETER Instance
    
    The Team Services account or TFS server.
    
    .PARAMETER Collection
    
    For Azure DevOps the value for collection should be the name of your orginization. 
    For both Team Services and TFS The value should be DefaultCollection unless another collection has been created.

    .PARAMETER Project
    
    Project ID or project name.

    .PARAMETER ApiVersion
    
    Version of the api to use.

    .PARAMETER PersonalAccessToken
    
    Personal access token used to authenticate that has been converted to a secure string. 
    It is recomended to uses an Azure Pipelines PS session to pass the personal access token parameter among funcitons, See New-APSession.
    https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts

    .PARAMETER Credential

    Specifies a user account that has permission to send the request.

    .PARAMETER Proxy
    
    Use a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.

    .PARAMETER ProxyCredential
    
    Specifie a user account that has permission to use the proxy server that is specified by the -Proxy parameter. The default is the current user.

    .PARAMETER Session

    Azure DevOps PS session, created by New-APSession.


    .PARAMETER EnvironmentId

    The name or id of the environment to create the approval for.

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

    Creates an Azure DevOps environment approval for 'My DisplayName'.

    New-APEnvironmentBranchCheck -Session $session -DisplayName 'My DisplayName' -EnvironmentId 2 -TimeoutDays 3 -BranchFilter "master,refs/heads/master" -EnsureProtectionOfBranch $false

    .LINK

    Undocumented at the time this was created.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByPersonalAccessToken')]
    Param
    (
        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [uri]
        $Instance,

        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [string]
        $Collection,

        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [string]
        $Project,

        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [string]
        $ApiVersion,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [Security.SecureString]
        $PersonalAccessToken,

        [Parameter(ParameterSetName = 'ByCredential')]
        [pscredential]
        $Credential,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(ParameterSetName = 'ByCredential')]
        [string]
        $Proxy,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(ParameterSetName = 'ByCredential')]
        [pscredential]
        $ProxyCredential,

        [Parameter(Mandatory,
            ParameterSetName = 'BySession')]
        [object]
        $Session,

        [Parameter(Mandatory)]
        [string]
        $EnvironmentId,

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
        If ($PSCmdlet.ParameterSetName -eq 'BySession')
        {
            $currentSession = $Session | Get-APSession
            If ($currentSession)
            {
                $Instance = $currentSession.Instance
                $Collection = $currentSession.Collection
                $Project = $currentSession.Project
                $PersonalAccessToken = $currentSession.PersonalAccessToken
                $Credential = $currentSession.Credential
                $Proxy = $currentSession.Proxy
                $ProxyCredential = $currentSession.ProxyCredential
                If ($currentSession.Version)
                {
                    $ApiVersion = (Get-APApiVersion -Version $currentSession.Version)
                }
                else
                {
                    $ApiVersion = $currentSession.ApiVersion
                }
            }
        }
    }
        
    process
    {
        $apSplat = @{
            Instance    = $Instance
            Collection  = $Collection
            ApiVersion  = $ApiVersion
            ErrorAction = 'Stop'
        }
        If ($PersonalAccessToken)
        {
            $apSplat.PersonalAccessToken = $PersonalAccessToken
        }
        If ($Credential)
        {
            $apSplat.Credential = $Credential
        }
        If ($Proxy)
        {
            $apSplat.Proxy = $Proxy
        }
        If ($ProxyCredential)
        {
            $apSplat.ProxyCredential = $ProxyCredential
        }
        $apEnvironment = Get-APEnvironment @apSplat -EnvironmentId $EnvironmentId -Project $Project
        $resource = @{
            type = 'environment'
            id   = $apEnvironment.Id
            name = $apEnvironment.Name
        }
        $body = Get-APBranchCheckBody `
            -Resource $resource `
            -TimeoutDays $TimeoutDays `
            -BranchFilter $BranchFilter `
            -EnsureProtectionOfBranch $EnsureProtectionOfBranch

        $apiEndpoint = Get-APApiEndpoint -ApiType 'pipelines-configurations'
        $setAPUriSplat = @{
            Collection  = $Collection
            Instance    = $Instance
            Project     = $Project
            ApiVersion  = $ApiVersion
            ApiEndpoint = $apiEndpoint
        }
        [uri] $uri = Set-APUri @setAPUriSplat
        $invokeAPRestMethodSplat = @{
            Method              = 'POST'
            Uri                 = $uri
            Credential          = $Credential
            PersonalAccessToken = $PersonalAccessToken
            Body                = $body
            ContentType         = 'application/json'
            Proxy               = $Proxy
            ProxyCredential     = $ProxyCredential
        }
        $results = Invoke-APRestMethod @invokeAPRestMethodSplat 
        If ($results.value)
        {
            $results.value
        }
        else
        {
            $results
        }
    }

    end
    {
 
    }
}