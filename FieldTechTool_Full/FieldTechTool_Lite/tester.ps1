# Imports
. .\Scripts\Diagnostics\gather_logs.ps1
. .\Scripts\Administration\DPLink_HPIA_Final_Updates.ps1



# Backup-DumpFiles
Check-Graphics


# Time to start creating outline for the MsOnline/exchange scripts. Will take another look at the scripts that Jack gave you to build on. 

# Work on Remote Desktop Prep script from Jack. Need to investigate if nVidia has an API to help find and download the appropriate driver. 
# nVidia does not have a public API to query. Will put together a repo of drivers for the machines we maintain and update them like HPIA. 
# Not sure how large these install files will be. Hopefully the suite will be small enough as to not make up a folder more than 500MB. 
# List of CAD machines to consider: 
    # ZBook Studio G9
    # HP Firefly G10