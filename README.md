# Birdie                                                                                                                             
A Vim plugin that facilitates Verilog netlist tracing. It is called Birdie because this name sounds like the commercial tool V\*\*d\*, and the user can hop like a bird going from one place to another in the Verilog netlist forrest.

![Birdie in action](https://github.com/tklam/birdie/blob/9f1e6b2807c2ab9fd65dd180b792acf6172794e6/birdie.gif)
  
## Installation
### Dependencies
```
pip install hdlConvertor
```

If you cannot acces the network, you can install using the included Python Wheel file converted from
the [official Egg
file](https://files.pythonhosted.org/packages/b8/dc/994c28ffa5a6a9d5a83baa630ce8b6da1da92abcd83ed582b83c7b5eb104/hdlConvertor-2.3-py3.8-linux-x86_64.egg):

```
pip install python/hdlConverter/hdlConvertor-2.3-py38-cp38-linux_x86_64.whl
# If the above command does not work, try using the the following build
pip install python/hdlConverter/hdlConvertor-2.3-cp311-cp311-linux_x86_64.whl
```

### Vim
Just :source the given vim_plugin/birdie.vim
   
## Available commands
Commands should be invoked in the window showing the netlist.

Parse a Verilog netlist using the closed source parser:
```
:Parse
:ParseAll
```
The parser is a binary compatible with x86_64 Linux distros with kernel > = 2.6.32. *:Parse* just extracts the user-defined Verilog modules and instances; whereas *:ParseAll* extracts everything.

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

Thanks @ZhukovAlexander for his [Python skiplist library](https://github.com/ZhukovAlexander/py-skiplist).
