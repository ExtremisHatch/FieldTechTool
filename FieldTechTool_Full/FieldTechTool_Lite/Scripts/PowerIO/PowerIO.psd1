@{
    # Script module or binary module file associated with this manifest.
    RootModule = '.\PowerIOUtils\BasePowerIO.ps1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'fd916be6-4e5d-4246-b23c-4699d7134ce9'

    # Author of this module
    Author = 'Koupa Taylor'

    # Company or vendor of this module
    CompanyName = 'Hatch'

    # Copyright statement for this module
    Copyright = '(c) 2025 Koupa. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module contains the TextTools for PowerIO.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @('.\PowerIOUtils\TextTools.ps1', '.\PowerIOUtils\OutputTools.ps1', '.\PowerIOUtils\BasePowerIO.ps1', '.\PowerIOUtils\InputTools.ps1')

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @()

    # Functions to export from this module
    FunctionsToExport = @('*')

    # Cmdlets to export from this module
    CmdletsToExport = @('*')

    # Variables to export from this module
    VariablesToExport = @('*')

    # Aliases to export from this module
    AliasesToExport = @('*')

    # DSC resources to export from this module
    DscResourcesToExport = @('*')

    # List of all modules packaged with this module
    ModuleList = @()

    # List of all files packaged with this module
    FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{}

    # HelpInfo URI of this module
    HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    DefaultCommandPrefix = ''
}