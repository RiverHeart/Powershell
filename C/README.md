# Lets C Some Powershell!

## Warning

Keep in mind that everything here is experimental. I'm just playing around here as a newbie. Nothing here is supported so do not use this for production. At all. If you want something guaranteed to work go elsewhere. Where? Visual Studio 2017 Community and Linux are good places. The most I can say about this setup is that I can compile "Hello World". Now then, if you wish to experiment with me, please continue. Otherwise, turn back and spare yourself.

## Preface

Hello fair reader. How you came to this page is a mystery but sit down for a moment and indulge me. I found out that Visual Studio provides tools for compiling C files. These are CL (Compiler), Link (Linker) and Nmake (Make) Alas, they do not appear to be widely used outside the Visual Studio ecosystem. So I ask you, do these tools not deserve love? Do I not deserve to write C code on Windows without being shackled to Visual Studio? I do and I shall until I become bored again.

## Setting Up the Dev Environment

To start, you need one of two things, [Visual Studio](https://visualstudio.microsoft.com/) or [Build Tools for Visual Studio 2017](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2017). Settle down, you don't need to use Visual Studio, you just need the files that come with it. In **C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC** you'll find all the goodies. At least until they bump that version number. Files such as **vcvars32.bat** and **vsvars64.bat** and **vcvarsall.bat** typically get run to setup the dev environment for you and handle much more than just C. That said, batch files are old school. Us? We're new wave. That's why I've taken the pieces relevent to C dev and put them into a Powershell script called **C_EnvironmentLite.ps1**. Paths get added to enviroment variables and dos commands cl and nmake get wrapped in Powershell functions. Short, sweet, and easy to understand.

After running the script you can compile and/or make files such as the ones in this repo to your hearts content. If you want this environment always available you can of course source the script in your Powershell profile.

P.S. If you want to use this with VSCode, most def source this in your Powershell profile.

## Integrating Visual C Into VSCode

Now it is all well and dandy that we can compile stuff from the terminal but people like editors. Some people like editors other than Visual Studio. Did I mention that already? Let's say **YOU** gentle reader want to use VSCode instead. Well Microsoft has kindly provided the C/C++ Extension for VSCode which you can download for syntax completion and auto-complete. It does not, however, come with a compiler and they encourage you to use something modern and sane like mingw-w64 for compiling on Windows. Psshaw...! This isn't about sanity. This is about hacking something together with glue and toothpicks!

In VSCode, select **View** from the menu bar and click on **Integrated Terminal**. The terminal is a Powershell terminal by default! Huzzah! And if you sourced **C_EnvironmentLite.ps1** in your profile then those commands and variables are available here. Huzzah again! But wait, there's more! Press `Ctrl+Shift+P` to open the command palette and select **Tasks: Edit Configuration** to generate a tasks.json file. Here we can create tasks to run make as our "build" tool and run the executable we produce as a "run" task.

## Conclusion

And there you have it. Compiling C with VSCode and not Visual Studio. Have an improvement on this? Let me know!
