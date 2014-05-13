﻿# Updates the working directory with the most current codebase using ROBOCOPY. If an existing codebase has already been deployed here, ROBOCOPY will attempt to mirror the
# existing code with the current build (changed local files will be overwritten, same files will be ignored) for speed.
robocopy $pipelineItemPath $WorkingDirectory /XA:HS /E /NDL /NP /XF README.overlay /R:20 2>&1 | out-host

if($LASTEXITCODE -gt 7) {
    Log-Error "Robocopy for overlay $pipelineItemPath threw an error. Aborting." -Abort
}