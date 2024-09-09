@echo off

::duplicate high performance power plan
for /f "usebackq tokens=4" %%a in (`powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`) do (set "GUID=%%a")

::give the new power plan a nice name
powercfg /changename %GUID% "Ultra Performance" "Made by Duckling"

::USB selective suspend setting - Disabled
powercfg /setacvalueindex %GUID% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

::USB 3 Link Power Mangement - Off
powercfg /setacvalueindex %GUID% 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0

::Allow Throttle States - Off
powercfg /setacvalueindex %GUID% SUB_PROCESSOR THROTTLING 0

::Processor idle demote threshold - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR IDLEDEMOTE 100

::Processor idle promote threshold - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR IDLEPROMOTE 100

::Turn off display after - 0
powercfg /setacvalueindex %GUID% SUB_VIDEO VIDEOIDLE 0

::Allow Standby States - Off
::Disables sleep functionality, no other benefits
powercfg /setacvalueindex %GUID% SUB_SLEEP ALLOWSTANDBY 0

::Processor performance time check interval - 5000
::Remove this setting from the script if you use dynamic core frequency technologies (such as Intel Turbo Boost 3.0 or Ryzen PBO)
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFCHECK 5000


::DISABLE CORE PARKING SECTION
::Remove this section from the script if your processor requires core parking for scheduling

::Processor performance core parking min cores - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR CPMINCORES 100

::Processor performance core parking min cores for Processor Power Efficiency Class 1 - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR CPMINCORES1 100


choice /c yn /m "Set power plan as active?"
if %errorlevel% EQU 1 (powercfg /s %GUID%)