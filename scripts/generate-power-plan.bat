@echo off

::duplicate high performance power plan
for /f "usebackq tokens=4" %%a in (`powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`) do (set "GUID=%%a")

::give the new power plan a nice name
powercfg /changename %GUID% "Ultra Performance" "Made by Duckling"

::Turn off hard disk after - 0
powercfg /setacvalueindex %GUID% SUB_DISK DISKIDLE 0

::Allow Standby States - Off
powercfg /setacvalueindex %GUID% SUB_SLEEP ALLOWSTANDBY 0

::USB selective suspend setting - Disabled
powercfg /setacvalueindex %GUID% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

::USB 3 Link Power Mangement - Off
powercfg /setacvalueindex %GUID% 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0

::Deep Sleep Enabled/Disabled - Deep Sleep Disabled
powercfg /setacvalueindex %GUID% SUB_IR DEEPSLEEP 0

::Allow Throttle States - Off
powercfg /setacvalueindex %GUID% SUB_PROCESSOR THROTTLING 0

::Processor idle demote threshold - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR IDLEDEMOTE 100

::Processor performance time check interval - 5000
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFCHECK 5000

::Processor idle promote threshold - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR IDLEPROMOTE 100

::Turn off display after - 0
powercfg /setacvalueindex %GUID% SUB_VIDEO VIDEOIDLE 0


::DISABLE CORE PARKING SECTION
::Remove this section if your processor requires core parking for scheduling

::Processor performance core parking min cores - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR CPMINCORES 100

::Processor performance core parking min cores for Processor Power Efficiency Class 1 - 100
powercfg /setacvalueindex %GUID% SUB_PROCESSOR CPMINCORES1 100


::P-STATE SECTION
::This section impacts P-state behavior only when hardware-controlled P-states aren't available

::Processor performance increase threshold - 10
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFINCTHRESHOLD 10

::Processor performance increase threshold for Processor Power Efficiency Class 1 - 10
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFINCTHRESHOLD1 10

::Processor performance decrease threshold - 0
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFDECTHRESHOLD 0

::Processor performance decrease threshold for Processor Power Efficiency Class 1 - 0
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFDECTHRESHOLD1 0

::Processor performance decrease policy - Single
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFDECPOL 1

::Processor performance decrease policy for Processor Power Efficiency Class 1 - Single
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFDECPOL1 1

::Processor performance increase policy - Rocket
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFINCPOL 2

::Processor performance increase policy for Processor Power Efficiency Class 1 - Rocket
powercfg /setacvalueindex %GUID% SUB_PROCESSOR PERFINCPOL1 2


choice /c yn /m "Set power plan as active?"
if %errorlevel% EQU 1 (powercfg /s %GUID%)