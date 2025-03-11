(*
Open Terminal in Folder - Version 1.1.0
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

on run {input, parameters}
	-- Initialize debug log
	set debugLog to {"Debug Log:"}
	
	try
		-- Step 1: Check input
		if (count of input) is 0 then
			set end of debugLog to "Warning: No items provided in input."
			set end of debugLog to "Input received: " & (input as text)
			try
				set end of debugLog to "Parameters received: " & (parameters as text)
			on error
				set end of debugLog to "Parameters received: [Complex record, cannot display as text]"
			end try
			
			display dialog "No item detected from Finder. Please select a folder by left-clicking it first, then try again." buttons {"OK"} default button "OK" with icon caution
			
			set end of debugLog to "Prompting user to choose a folder."
			set selectedFolder to choose folder with prompt "Choose a folder to open in Terminal:"
			set itemPath to POSIX path of selectedFolder
			set end of debugLog to "User-selected folder path: " & itemPath
		else
			set end of debugLog to "Input count: " & (count of input)
			set selectedItem to item 1 of input
			set end of debugLog to "Selected item: " & (selectedItem as text)
			set itemPath to POSIX path of (selectedItem as alias)
			set end of debugLog to "Initial POSIX path: " & itemPath
			
			-- Step 2: Handle folder actions
			tell application "Finder"
				set itemClass to class of selectedItem
				set itemKind to kind of selectedItem
				set end of debugLog to "Class of selected item: " & (itemClass as text)
				set end of debugLog to "Kind of selected item: " & itemKind
				
				if (itemClass is in {folder, alias}) and (itemKind is "Folder") then
					set isFolder to true
					set end of debugLog to "Item confirmed as a folder or folder alias."
					
					-- Determine folder action based on defaultFolderAction
					if defaultFolderAction is "ASK" then
						set folderOptions to {"Open Terminal INSIDE this folder", "Open Terminal at this folder's LEVEL"}
						set userChoice to choose from list folderOptions with prompt "You selected a folder. Where should the Terminal open?" default items {"Open Terminal INSIDE this folder"} OK button name "OK" cancel button name "Cancel"
						set end of debugLog to "Prompted user with choose from list."
						
						if userChoice is false then
							set end of debugLog to "User canceled the folder location choice."
							error "Operation canceled by user."
						else if item 1 of userChoice is "Open Terminal at this folder's LEVEL" then
							set itemPath to POSIX path of (container of (selectedItem as alias) as alias)
							set end of debugLog to "User chose folder level; new path: " & itemPath
						else
							set end of debugLog to "User chose inside folder; keeping path: " & itemPath
						end if
					else if defaultFolderAction is "INSIDE" then
						set end of debugLog to "Default action is INSIDE; keeping path: " & itemPath
					else if defaultFolderAction is "LEVEL" then
						set itemPath to POSIX path of (container of (selectedItem as alias) as alias)
						set end of debugLog to "Default action is LEVEL; new path: " & itemPath
					end if
				else
					set isFolder to false
					set end of debugLog to "Item is not a folder (class: " & (itemClass as text) & ", kind: " & itemKind & "); getting container path."
					set itemPath to POSIX path of (container of (selectedItem as alias) as alias)
					set end of debugLog to "Container POSIX path: " & itemPath
				end if
			end tell
		end if
		
		-- Step 3: Open Terminal (DIRECT SHELL APPROACH)
		set end of debugLog to "Final path for cd: " & itemPath
		
		-- Use direct shell command to open Terminal with our path
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