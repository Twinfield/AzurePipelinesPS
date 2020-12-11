function New-APEnvironmentK8sResource
{
    <#
    .SYNOPSIS

    Creates an Azure Pipeline environment K8s resource.

    .DESCRIPTION

    Creates an Azure Pipeline environment k8s resource based on environment id.
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

    .PARAMETER K8sClusterName

    The k8s cluster name to be used.

    .PARAMETER K8sResourceName

    The k8s resource name.

    .PARAMETER K8sNamespace

	The k8s namespace to be used for resource.
	
	.PARAMETER ServiceEndpointId

    Servcie endpoint ID to work with K8s resource

    .INPUTS
    
    None, does not support pipeline.

    .OUTPUTS

    PSObject, Azure Pipelines environment.

    .EXAMPLE

    Creates an Azure DevOps environment approval for 'My DisplayName'.

    New-APEnvironmentK8sResource -Session $session -EnvironmentId 2 -K8sNamespace master -K8sClusterName accept-app-aks -K8sResourceName master -ServiceEndpointId "xxx-xxx-xx-xx"

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
        [string]
        $K8sClusterName, 

        [Parameter()]
        [string]
        $K8sNamespace,

        [Parameter(Mandatory)]
        [string]
        $K8sResourceName,

        [Parameter(Mandatory)]
        [string]
        $ServiceEndpointId
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
        $body = @{
            clusterName = $K8sClusterName
            name = $K8sResourceName
            namespace = $K8sNamespace
            tags = @()
            serviceEndpointId = $ServiceEndpointId
        }
        $apiEndpoint = Get-APApiEndpoint -ApiType 'distributedtask-environments-k8s-resource'
        $apiEndpoint = $apiEndpoint.Replace('{0}', $apEnvironment.id)
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