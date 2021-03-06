function global:GetMainMenuItems
{
    param($menuArgs)

    $menuItem1 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem1.Description = "MetaCritic (without prompting)"
    $menuItem1.FunctionName = "AddLinkMetaCriticNoPrompt"
    $menuItem1.MenuSection = "@Add Link"

    $menuItem2 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem2.Description = "IGDB (without prompting)"
    $menuItem2.FunctionName = "AddLinkIGDBNoPrompt"
    $menuItem2.MenuSection = "@Add Link"
    
    $menuItem3 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem3.Description = "MetaCritic (prompts to confirm)"
    $menuItem3.FunctionName = "AddLinkMetaCritic"
    $menuItem3.MenuSection = "@Add Link"

    $menuItem4 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem4.Description = "IGDB (prompts to confirm)"
    $menuItem4.FunctionName = "AddLinkIGDB"
    $menuItem4.MenuSection = "@Add Link"

    return $menuItem1, $menuItem2, $menuItem3, $menuItem4
}
function global:GetGameMenuItems()
{
    param($menuArgs)

    $menuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $menuItem.Description =  "Metacritic"
    $menuItem.FunctionName = "global:AddLinkMetaCritic"
    $menuItem.MenuSection = "Add Link"
   
    $menuItem2 = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $menuItem2.Description =  "IGDB"
    $menuItem2.FunctionName = "global:AddLinkIGDB"
    $menuItem2.MenuSection = "Add Link"

    return $menuItem, $menuItem2
}
function global:AddLinkMetaCritic()
{
    $searchUrl = "https://www.metacritic.com/search/game/{0}/results?plats[3]=1&search_type=advanced"
    $gameUrlTemplate = "https://www.metacritic.com/game/pc/{0}"
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000
    
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the MetaCritic url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" & ","-").Replace(" - ","-").Replace(" ","-").Replace(":","").Replace(".","").Replace("'","").Replace("&","").Replace("  "," ")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already a MetaCritic link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "MetaCritic"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box #>
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        } else {
            $gameUrl = $response.SelectedString
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("MetaCritic",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timer.Stop()
        if ($timer.Elapsed.Milliseconds -lt $interval) {Start-Sleep -Milliseconds ($interval - $timer.Elapsed.Milliseconds) }
    }
}
function global:AddLinkIGDB()
{
    $searchUrl = "https://www.igdb.com/search?utf8=%E2%9C%93&type=1&q={0}"
    $gameUrlTemplate = "https://www.igdb.com/games/{0}"
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000

    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the IGDB url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-").Replace("/","slash")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"[:\.'&,!]","")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"-{2,}","-")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already an IGDB link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "IGDB"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box
        #>
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        } else {
            $gameUrl = $response.SelectedString
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("IGDB",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timer.Stop()
        if ($timer.Elapsed.Milliseconds -lt $interval) {Start-Sleep -Milliseconds ($interval - $timer.Elapsed.Milliseconds) }
    }
}
function global:AddLinkMetaCriticNoPrompt()
{
    $searchUrl = "https://www.metacritic.com/search/game/{0}/results?plats[3]=1&search_type=advanced"
    $gameUrlTemplate = "https://www.metacritic.com/game/pc/{0}"
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000
    
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the MetaCritic url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" & ","-").Replace(" - ","-").Replace(" ","-").Replace(":","").Replace(".","").Replace("'","").Replace("&","").Replace("  "," ")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already a MetaCritic link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "MetaCritic"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box #>
        ##Start-Process ($searchUrl -f $game.Name)
        ##Start-Process $gameUrl
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        # ask if this is the correct url
        ##$response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        ##if (-not $response.Result) {
        ##    $gameUrl = ""
        ##    Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        ##} else {
        ##   $gameUrl = $response.SelectedString
        ##}

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("MetaCritic",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timer.Stop()
        if ($timer.Elapsed.Milliseconds -lt $interval) {Start-Sleep -Milliseconds ($interval - $timer.Elapsed.Milliseconds) }
    }
}
function global:AddLinkIGDBNoPrompt()
{
    $searchUrl = "https://www.igdb.com/search?utf8=%E2%9C%93&type=1&q={0}"
    $gameUrlTemplate = "https://www.igdb.com/games/{0}"
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000

    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the IGDB url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-").Replace("/","slash")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"[:\.'&,!]","")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"-{2,}","-")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already an IGDB link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "IGDB"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box
        #>
        ##Start-Process ($searchUrl -f $game.Name)
		## Start-Process $gameUrl
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        # ask if this is the correct url
        ##$response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        ##if (-not $response.Result) {
        ##    $gameUrl = ""
        ##    Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        ##} else {
        ##    $gameUrl = $response.SelectedString
        ##}

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("IGDB",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timer.Stop()
        if ($timer.Elapsed.Milliseconds -lt $interval) {Start-Sleep -Milliseconds ($interval - $timer.Elapsed.Milliseconds) }
    }
}
function global:FixLink()
{
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        $link = $game.Links | Where-Object {$_.Url.StartsWith("https://www.igdb")}
        if ($link -ne $null) {$link.Name = "IGDB"}
        $PlayniteApi.Database.Games.Update($game)
    }
}
