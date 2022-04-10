# Birdie                                                                                                                             
A Vim plugin that facilitates Verilog netlist tracing. It is called Birdie because this name sounds like the commercial tool V\*\*d\*, and the user can hop like a bird going from one place to another in the Verilog netlist forrest.

![Birdie in action](https://github.com/tklam/birdie/blob/9f1e6b2807c2ab9fd65dd180b792acf6172794e6/birdie.gif)
  
## Installation
Just :source the given vim_plugin/birdie.vim
   
## Available commands
Commands should be invoked in the window showing the netlist.

Parse a Verilog netlist using the closed source parser:
```
:Parse
:ParseAll
```
The parser is an binary compatible with x86_64 Linux distros with kernel > = 2.6.32. *:Parse* just extracts the user-defined Verilog modules and instances; whereas *:ParseAll* extracts everything.

Show the information of the module under the cursor:
```
:Module
```  

Go to the definition of the module whose name matches with the given regular expression:
```
:GoToModule <module name regex, e.g. free.*dom>
```

Go to the declaration of the instance whose instance path matches with the given regular expression:
```
:GoToInstance <instance path regex, e.g. /top_module_name/path/to/instanc.*>
```

Extract the definition of a module and put it on a separate buffer/window:
```
:OneModule <module name regex, e.g. free.*dom>
```                                            

Show the hierarchy of the design:
```
:Hier
```
