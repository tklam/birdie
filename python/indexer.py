import py_skiplist.skiplist as skiplist
import re

class VerilogModuleIndexer:
    def __init__(self):
        self.file_2_skiplist = {} # One skiplist for each Verilog file: file_path -> skiplist
        self.name_2_modules = {} # module name -> module
        self.instance_path_2_module = {} # module name -> module
        self.top_modules = {} # XXX TODO not using a list to deal with duplicated entries in the ugly DB


    def index(self, verilog_module):
        # name
        self.name_2_modules[verilog_module._module_name] = verilog_module

        # instance

        # location in the Verilog file
        sk_list = None
        if verilog_module._file_path not in self.file_2_skiplist:
            sk_list = skiplist.Skiplist()
            self.file_2_skiplist[verilog_module._file_path] = sk_list
        else:
            sk_list = self.file_2_skiplist[verilog_module._file_path]

        sk_list[int(verilog_module._file_begin_line_number)] = (verilog_module, 'BEGIN')
        sk_list[int(verilog_module._file_end_line_number)] = (verilog_module, 'END')

        for i in verilog_module._instances:
            self.instance_path_2_module[i] = verilog_module

        if verilog_module._is_top:
            self.top_modules[verilog_module._module_name] = verilog_module


    def find_module_definition_by_line_number(self, file_path, line_number):
        if file_path not in self.file_2_skiplist:
            return (False, None)

        sk_list = self.file_2_skiplist[file_path]
        exact, one_smaller = sk_list.get_exact_and_just_smaller(int(line_number))
        if exact is None:
            return (False, one_smaller)
        else:
            return (True, exact)


    def find_module_definition_by_name(self, module_name):
        # 1. exact match
        if module_name in self.name_2_modules:
            return [module_name], self.name_2_modules[module_name]

        print('Start fuzzy search')
        # 2. try fuzzy match
        candidates = []
        pattern = re.compile(r'' + module_name)
        for i in self.name_2_modules.keys():
            match_result = pattern.match(i)
            if match_result is None:
                continue
            candidates.append(i)

        num_candidates = len(candidates)
        if num_candidates == 1:
            return [candidates[0]], self.name_2_modules[candidates[0]]
        elif num_candidates > 1:
            return candidates, None

        return [], None


    def find_module_definition_by_instance_path(self, instance_path):
        # 1. exact match
        if instance_path in self.instance_path_2_module:
            return [instance_path], self.instance_path_2_module[instance_path]

        # can te a top module, or the given instance path matches more than one instance paths

        print('Start fuzzy search')
        # 2. try fuzzy match
        candidates = []
        pattern = re.compile(r'' + instance_path)
        for i in self.instance_path_2_module.keys():
            match_result = pattern.match(i)
            if match_result is None:
                continue
            candidates.append(i)

        num_candidates = len(candidates)
        if num_candidates == 1:
            return [candidates[0]], self.instance_path_2_module[candidates[0]]
        elif num_candidates > 1:
            return candidates, None

        return [], None


    def has_index_file(self, file_path):
        if file_path in self.file_2_skiplist:
            return True
        return False
