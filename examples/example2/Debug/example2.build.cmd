set PATH=C:\D\dmd2\windows\bin;C:\Program Files\Microsoft SDKs\Windows\v7.1\\bin;%PATH%
dmd -g -debug -X -Xf"Debug\example2.json" -deps="Debug\example2.dep" -c -of"Debug\example2.obj" winmain.d
if errorlevel 1 goto reportError

set LIB="C:\D\dmd2\windows\bin\\..\lib"
echo. > Debug\example2.build.lnkarg
echo "Debug\example2.obj","Debug\example2.exe_cv","Debug\example2.map",ole32.lib+ >> Debug\example2.build.lnkarg
echo kernel32.lib+ >> Debug\example2.build.lnkarg
echo user32.lib+ >> Debug\example2.build.lnkarg
echo comctl32.lib+ >> Debug\example2.build.lnkarg
echo comdlg32.lib+ >> Debug\example2.build.lnkarg
echo user32.lib+ >> Debug\example2.build.lnkarg
echo kernel32.lib/NOMAP/CO/NOI /SUBSYSTEM:WINDOWS >> Debug\example2.build.lnkarg

"C:\Tools\VisualDAddon\pipedmd.exe" -deps Debug\example2.lnkdep link.exe @Debug\example2.build.lnkarg
if errorlevel 1 goto reportError
if not exist "Debug\example2.exe_cv" (echo "Debug\example2.exe_cv" not created! && goto reportError)
echo Converting debug information...
"C:\Tools\VisualDAddon\cv2pdb\cv2pdb.exe" "Debug\example2.exe_cv" "Debug\example2.exe"
if errorlevel 1 goto reportError
if not exist "Debug\example2.exe" (echo "Debug\example2.exe" not created! && goto reportError)

goto noError

:reportError
echo Building Debug\example2.exe failed!

:noError
