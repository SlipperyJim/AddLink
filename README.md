# AddLink
AddLink Extension for Playnite

Manual Install:
1. Create a folder called AddLink in %appdata%\Playnite\Extensions.
2. Copy the two files (Addlink.ps1 and extension.yaml) to the folder.
3. Make sure the extension is enabled in Playnite -> Settings -> Extensions.

To use, select one or multiple games and run the appropriate command from the Extensions menu, or select a single game in details view and choose the command from the settings menu (F3).

NOTES:
The vast majority of this script was created by dragonmc, so practically all of the credit should go to him. The original version is here:

https://github.com/dragonmc77/AddLink

I have simply tweaked it to give it additional options and menu entries.

Dragonmc valued accuracy over speed, so his original script was designed to get you to confirm all links before they are added to Playnite. I found that, in most cases it is quite good at guessing the correct link and that confirming each time, when you may be wanting to add links to tens or hundreds of games, was very time consuming.

I therefore added the option so that it will just automatically enter its 'best guess' for a link without you having to do anything. You can therefore select a whole bunch of games and simply set it going (bearing in mind though that Playnite will not be usable while it does it).

If you do choose the option for it to prompt, the extension goes through each game and opens up two web pages. One is the best attempt at the correct URL for the game. If this URL is correct (i.e. you see the page for the game load) then simply click OK on the dialog box (that will be hidden behind the browser window) and it will add a link and move to the next game. If not correct, it loads a second browser page which is a search of the game on the site. YIf it finds the correct game you can then copy the correct link from the address bar for the game and paste it in the dialog box in Playnite to add the link.

In both cases, there is a 5 second wait timer built in between games, because attempting to load pages too fast from either of these sites will trigger an error and timeout before you are allowed access again. Refer to the code for the particulars.
