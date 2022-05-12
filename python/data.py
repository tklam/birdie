class VerilogModule:
    def __init__(self):
        self._module_name = 'undefined'
        self._is_user_defined = True
        self._file_path = 'undefined'
        self._file_begin_line_number = -1
        self._file_end_line_number = -1
        self._inputs= []
        self._outputs = []
        self._inouts = []
        self._instances = [] # list of instances of this module
        self._submodules = [] # lis of pair(instance path of the submodule, submodule name)
        self._is_top = False # whether this module is a top module (without any instance)


    def __str__(self):
        s = []
        s.append('Module: {0}'.format(self._module_name))
        s.append('  is user defined : {0}'.format(self._is_user_defined))
        s.append('  file path: {0}'.format(self._file_path))
        s.append('  from line {0} to {1}'.format(self._file_begin_line_number, self._file_end_line_number))
        s.append('  inputs:')
        for i in self._inputs:
            s.append('    {0}'.format(i))
        s.append('  outputs:')
        for i in self._outputs:
            s.append('    {0}'.format(i))
        s.append('  inouts:')
        for i in self._inouts:
            s.append('    {0}'.format(i))
        s.append('  instances:')
        for i in self._instances:
            s.append('    {0}'.format(i))
        s.append('  submodule instances:')
        for i in self._submodules:
            s.append('    {0} <{1}>'.format(i[0], i[1]))
        return '\n'.join(s)


def recursive_traverse_sub_instances(level, instance_path_2_module, cur_module, cur_path, callback_obj):
    callback_obj.hierarchy_print_module(cur_module, str(level) + ' ' * (level-len(str(level))+1) + cur_path)
    for sub_instance_path, _ in cur_module._submodules:
        child_path = cur_path + '/' + sub_instance_path 
        if child_path not in instance_path_2_module:
            continue
        submodule = instance_path_2_module[child_path]
        recursive_traverse_sub_instances(level+1, instance_path_2_module, submodule, child_path, callback_obj)


class HierPrint:
    def __init__(self):
        self.buffer =  []


    def __str__(self):
        return '\n'.join(self.buffer)


    def hierarchy_print_module(self, module, path):
        if module._is_top:
            self.buffer.append(module._module_name)
        else:
            self.buffer.append(' {0} <{1}>'.format(path, module._module_name))

