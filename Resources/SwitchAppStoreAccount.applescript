-- Credentials are injected in memory by StoreSwitch. Never log these variables.
property targetEmail : "__STORE_SWITCH_APPLE_ID__"
property targetPassword : "__STORE_SWITCH_PASSWORD__"

on localeMenuNames()
	set lang to ""
	try
		set lang to do shell script "defaults read -g AppleLocale 2>/dev/null"
	end try
	if lang is "" then
		try
			set lang to user locale of (system info)
		end try
	end if
	if lang starts with "zh" then
		return {"商店", "登录", "退出登录"}
	else
		return {"Store", "Sign In", "Sign Out"}
	end if
end localeMenuNames

on ensureFront()
	tell application "App Store" to activate
	tell application "System Events" to tell process "App Store"
		try
			set frontmost to true
		end try
	end tell
end ensureFront

on probeSheet()
	tell application "System Events" to tell process "App Store"
		try
			if (count of sheets of window 1) is 0 then return {false, false, 0, 0}
			set useInner to false
			try
				if (count of text fields of (UI element 1 of sheet 1 of window 1)) > 0 then set useInner to true
			end try
			if useInner then
				set cont to UI element 1 of sheet 1 of window 1
			else
				set cont to sheet 1 of window 1
			end if
			set idIdx to 0
			set secIdx to 0
			set i to 0
			repeat with tf in text fields of cont
				set i to i + 1
				if (description of tf as text) is "secure text field" then
					set secIdx to i
				else
					set idIdx to i
				end if
			end repeat
			return {true, useInner, idIdx, secIdx}
		on error
			return {false, false, 0, 0}
		end try
	end tell
end probeSheet

on typeInField(useInner, idx, txt, doSelectAll, shouldSubmit)
	my ensureFront()
	tell application "System Events" to tell process "App Store"
		if useInner then
			set cont to UI element 1 of sheet 1 of window 1
		else
			set cont to sheet 1 of window 1
		end if
		set tf to text field idx of cont
		set focused of tf to true
		delay 0.3
		if doSelectAll then
			keystroke "a" using command down
			delay 0.2
		end if
		keystroke txt
		delay 0.3
		if shouldSubmit then
			key code 36
			delay 0.3
		end if
	end tell
end typeInField

on run
	tell application "App Store" to activate
	delay 1.5

	set menuNames to my localeMenuNames()
	set storeName to item 1 of menuNames
	set signInName to item 2 of menuNames
	set signOutName to item 3 of menuNames
	set signInCandidates to {signInName, signInName & "…", signInName & "..."}
	set signOutCandidates to {signOutName, signOutName & "…", signOutName & "..."}

	my ensureFront()
	delay 1.5
	tell application "System Events" to tell process "App Store"
		repeat 3 times
			if (count of sheets of window 1) is 0 then exit repeat
			key code 53
			delay 0.5
		end repeat

		set storeMenu to missing value
		repeat with menuBarItem in menu bar items of menu bar 1
			if (name of menuBarItem) is storeName then
				set storeMenu to menuBarItem
				exit repeat
			end if
		end repeat
		if storeMenu is missing value then error "找不到 App Store 的“" & storeName & "”菜单。"

		click storeMenu
		delay 0.5
		set didSignOut to false
		repeat with candidate in signOutCandidates
			try
				click menu item candidate of menu 1 of storeMenu
				set didSignOut to true
				exit repeat
			end try
		end repeat
		if didSignOut then
			delay 2
		else
			key code 53
		end if

		delay 0.5
		click storeMenu
		delay 0.5
		set clickedSignIn to false
		repeat with candidate in signInCandidates
			try
				click menu item candidate of menu 1 of storeMenu
				set clickedSignIn to true
				exit repeat
			end try
		end repeat
		if not clickedSignIn then
			key code 53
			error "找不到 App Store 的登录菜单项。"
		end if
	end tell

	set probe to {false, false, 0, 0}
	repeat 20 times
		delay 0.5
		set probe to my probeSheet()
		if item 1 of probe then exit repeat
	end repeat
	if not (item 1 of probe) then error "App Store 登录窗口没有出现。"
	delay 0.8
	set probe to my probeSheet()

	set useInner to item 2 of probe
	set idIdx to item 3 of probe
	set secIdx to item 4 of probe
	if idIdx > 0 then
		if secIdx is 0 then
			my typeInField(useInner, idIdx, targetEmail, true, true)
			repeat 20 times
				delay 0.5
				set probe to my probeSheet()
				if (item 1 of probe) and (item 4 of probe) > 0 then exit repeat
			end repeat
			if not ((item 1 of probe) and (item 4 of probe) > 0) then error "提交 Apple ID 后没有出现密码框。"
		else
			my typeInField(useInner, idIdx, targetEmail, true, false)
			set probe to my probeSheet()
		end if
	end if

	set useInner to item 2 of probe
	set secIdx to item 4 of probe
	if secIdx is 0 then error "没有找到 App Store 密码框。"
	my typeInField(useInner, secIdx, targetPassword, false, true)

	repeat 40 times
		delay 0.5
		set probe to my probeSheet()
		if not (item 1 of probe) then return "completed"
	end repeat
	return "needs_attention"
end run
