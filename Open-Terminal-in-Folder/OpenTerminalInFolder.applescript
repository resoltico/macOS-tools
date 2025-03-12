(*
Open Terminal in Folder - Version 1.2.0
Copyright (c) 2025 Ervins Strauhmanis
Licensed under the MIT License:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*)

property defaultFolderAction : "ASK" -- Options: "ASK", "INSIDE", "LEVEL"
property defaultAliasAction : "ASK" -- Options: "ASK", "TARGET", "ALIAS"

on run {input, parameters}
	-- Initialize debug log
	set debugLog to {"Debug Log:"}
	
	try
		-- Step 1: Check input
		if (count of input) is 0 then
			set end of debugLog to "Warning: No items provided in input."
			
			display dialog "No item detected from Finder. Please select a folder by left-clicking it first, then try again." buttons {"OK"} default button "OK" with icon caution
			
			set end of debugLog to "Prompting user to choose a folder."
			set selectedFolder to choose folder with prompt "Choose a folder to open in Terminal:"
			set itemPath to POSIX path of selectedFolder
			set end of debugLog to "User-selected folder path: " & itemPath
		else
			set end of debugLog to "Input count: " & (count of input)
			set selectedItem to item 1 of input
			set end of debugLog to "Selected item: " & (selectedItem as text)
			
			-- Step 2: Handle item using Finder for reliable type detection
			tell application "Finder"
				set itemClass to class of selectedItem
				set itemKind to kind of selectedItem
				set end of debugLog to "Class of selected item: " & (itemClass as text)
				set end of debugLog to "Kind of selected item: " & itemKind
				
				-- Only consider something a Finder alias if its Kind is exactly "Alias"
				-- This distinguishes between AppleScript's use of "alias" as a reference type
				-- and Finder's concept of an "Alias" as a file that points to another file
				set isFinderAlias to (itemKind is "Alias")
				set end of debugLog to "Is Finder alias: " & isFinderAlias
				
				if isFinderAlias then
					-- If it's a Finder alias, resolve it to get the original item
					set originalItem to original item of selectedItem
					set originalClass to class of originalItem
					set originalKind to kind of originalItem
					
					set end of debugLog to "Original item: " & (originalItem as text)
					set end of debugLog to "Original class: " & (originalClass as text)
					set end of debugLog to "Original kind: " & originalKind
					
					-- Get the containers of the alias and its target
					set aliasContainer to container of selectedItem
					set targetContainer to container of originalItem
					
					-- Determine whether to use target or alias location based on defaultAliasAction
					set useTarget to true -- Default to using target location
					
					if defaultAliasAction is "ASK" then
						-- Always ask the user which location to use (alias or target)
						set locationOptions to {"Open Terminal at TARGET location", "Open Terminal at ALIAS location"}
						set locationChoice to choose from list locationOptions with prompt "You selected an alias. Where should Terminal open?" default items {"Open Terminal at TARGET location"} OK button name "OK" cancel button name "Cancel"
						
						if locationChoice is false then
							set end of debugLog to "User canceled location choice."
							error "Operation canceled by user."
						else if item 1 of locationChoice is "Open Terminal at ALIAS location" then
							set useTarget to false
						end if
					else if defaultAliasAction is "ALIAS" then
						-- Automatically use the alias location without asking
						set useTarget to false
						set end of debugLog to "Using alias location (per defaultAliasAction setting)"
					else
						-- Default is "TARGET" - use target location without asking
						set end of debugLog to "Using target location (per defaultAliasAction setting)"
					end if
					
					if useTarget then
						-- Use target location - now check if it's a folder
						if originalClass is folder or (originalKind contains "folder") then
							-- Target is a folder - ask for folder action if needed
							if defaultFolderAction is "ASK" then
								set folderOptions to {"Open Terminal INSIDE this folder", "Open Terminal at this folder's LEVEL"}
								set userChoice to choose from list folderOptions with prompt "The target is a folder. Where should Terminal open?" default items {"Open Terminal INSIDE this folder"} OK button name "OK" cancel button name "Cancel"
								
								if userChoice is false then
									set end of debugLog to "User canceled folder location choice."
									error "Operation canceled by user."
								else if item 1 of userChoice is "Open Terminal at this folder's LEVEL" then
									-- Get parent of the original folder
									set itemPath to POSIX path of (container of originalItem as alias)
									set end of debugLog to "User chose folder level; path: " & itemPath
								else
									-- Use the original folder directly
									set itemPath to POSIX path of (originalItem as alias)
									set end of debugLog to "User chose inside folder; path: " & itemPath
								end if
							else if defaultFolderAction is "INSIDE" then
								set itemPath to POSIX path of (originalItem as alias)
								set end of debugLog to "Default action is INSIDE; path: " & itemPath
							else if defaultFolderAction is "LEVEL" then
								set itemPath to POSIX path of (container of originalItem as alias)
								set end of debugLog to "Default action is LEVEL; path: " & itemPath
							end if
						else
							-- Target is a file - use its container
							set itemPath to POSIX path of (container of originalItem as alias)
							set end of debugLog to "Target is a file; using its container: " & itemPath
						end if
					else
						-- Use alias location
						set itemPath to POSIX path of (container of selectedItem as alias)
						set end of debugLog to "Using alias container location: " & itemPath
					end if
				else
					-- Handle non-alias items (standard files and folders)
					if (itemClass is folder) or (itemKind contains "folder") then
						-- It's a folder - handle folder actions
						if defaultFolderAction is "ASK" then
							set folderOptions to {"Open Terminal INSIDE this folder", "Open Terminal at this folder's LEVEL"}
							set userChoice to choose from list folderOptions with prompt "You selected a folder. Where should Terminal open?" default items {"Open Terminal INSIDE this folder"} OK button name "OK" cancel button name "Cancel"
							
							if userChoice is false then
								set end of debugLog to "User canceled folder location choice."
								error "Operation canceled by user."
							else if item 1 of userChoice is "Open Terminal at this folder's LEVEL" then
								set itemPath to POSIX path of (container of selectedItem as alias)
								set end of debugLog to "User chose folder level; path: " & itemPath
							else
								set itemPath to POSIX path of (selectedItem as alias)
								set end of debugLog to "User chose inside folder; path: " & itemPath
							end if
						else if defaultFolderAction is "INSIDE" then
							set itemPath to POSIX path of (selectedItem as alias)
							set end of debugLog to "Default action is INSIDE; path: " & itemPath
						else if defaultFolderAction is "LEVEL" then
							set itemPath to POSIX path of (container of selectedItem as alias)
							set end of debugLog to "Default action is LEVEL; path: " & itemPath
						end if
					else
						-- It's a file - use its container
						set itemPath to POSIX path of (container of selectedItem as alias)
						set end of debugLog to "Item is a file; using its container: " & itemPath
					end if
				end if
			end tell
		end if
		
		-- Step 3: Open Terminal 
		set end of debugLog to "Final path for Terminal: " & itemPath
		
		-- We use 'open -a Terminal' instead of AppleScript's 'tell application "Terminal"'
		-- because the latter causes two Terminal windows to open (one at root, one at target)
		do shell script "open -a Terminal " & quoted form of itemPath
		set end of debugLog to "Opened Terminal directly at path."
		
		return input
		
	on error errMsg number errNum
		set end of debugLog to "Error occurred: " & errMsg
		set end of debugLog to "Error number: " & errNum
		
		choose from list debugLog with title "Debug Log" with prompt "An error occurred. Review the log below:" OK button name "Copy to Clipboard" cancel button name "Close"
		
		if result is not false then
			set logText to ""
			repeat with logLine in debugLog
				set logText to logText & logLine & return
			end repeat
			set the clipboard to logText
			display dialog "Debug log copied to clipboard." buttons {"OK"} default button "OK"
		end if
		
		error errMsg number errNum
	end try
end run