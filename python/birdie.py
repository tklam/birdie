# #!/usr/bin/env python2

# # python3 is actually preferred. But people living in the dark age have not even heard about python3.


from __future__ import print_function
import os
import subprocess
import json

from data import VerilogModule
from data import recursive_traverse_sub_instances
from data import HierPrint
from indexer import VerilogModuleIndexer


birdie_root_path = '../' # path to the root directory of this plugin
birdie_veriog_parser = '../dist/birdie' # path to the quick Verilog netlist parser: birdie
birdie_modules_db = './birdie.db'
birdie_limit_to_use_defined_modules_default = True


verilog_module_indexer = VerilogModuleIndexer()


def init(plugin_root_path):
    global birdie_root_path, birdie_veriog_parser
    birdie_root_path = plugin_root_path
    birdie_veriog_parser = birdie_root_path + os.path.sep + 'dist/birdie' # path to the quick Verilog netlist parser: birdie


def hello():
    print('Hello world from Birdie Verilog netlist tracer!')
    print('Env info:')
    print(' '*2 + 'Plugin path: {0}'.format(birdie_root_path))
    print(' '*2 + 'Path to the Verilog parser: {0}'.format(birdie_veriog_parser))


def tidy_db():
    # 1. deduplication
    cmd_status = subprocess.call('sort -u -o {0} {0}'.format(birdie_modules_db).split())
    print('deduplicate_db return code: {0}'.format(cmd_status))


def rm_db():
    os.remove(birdie_modules_db)


def parse_verilog(file_path, limit_to_use_defined_modules):
    # subprcess must not print anything, or vim will complaint 
    parser_cmd_status = subprocess.call([birdie_veriog_parser] + 
            [file_path, str(int(limit_to_use_defined_modules)), birdie_modules_db])
    print('Parser return code: {0}'.format(parser_cmd_status))

    with open(birdie_modules_db, 'r') as db:
        for l in db.readlines():
            verilog_module_json = json.loads(l)

            m = VerilogModule()
            m._module_name = verilog_module_json['_module_name']
            m._is_user_defined = verilog_module_json['_is_user_defined']
            m._file_path = verilog_module_json['_file_path']
            m._file_begin_line_number = verilog_module_json['_file_begin_line_number']
            m._file_end_line_number = verilog_module_json['_file_end_line_number']
            for i in verilog_module_json['_inputs']:
                m._inputs.append(i)
            for i in verilog_module_json['_outputs']:
                m._outputs.append(i)
            for i in verilog_module_json['_inouts']:
                m._inouts.append(i)
            for i in verilog_module_json['_instances']:
                m._instances.append(i)
            for i in verilog_module_json['_submodules']:
                for s,s_inst_list in i.items():
                    for l in s_inst_list:
                        m._submodules.append((l, s))
            if len(m._instances) == 0:
                m._is_top = True

            verilog_module_indexer.index(m)


def get_module_by_line_number(file_path, line_number):
    if not verilog_module_indexer.has_index_file(file_path):
        parse_verilog(file_path, birdie_limit_to_use_defined_modules_default)

    is_exact, verilog_module_tag = verilog_module_indexer.find_module_definition_by_line_number(file_path, line_number)
    if verilog_module_tag is None:
        return None

    verilog_module, tag = verilog_module_tag
    if not is_exact:
        if tag == 'BEGIN':
            return verilog_module
            # inside verilog_module's definition
        elif tag == 'END':
            # not in any verilog_module's definition
            return None
    return verilog_module


def get_module_by_name(module_name):
    candidate_module_names, verilog_module = verilog_module_indexer.find_module_definition_by_name(module_name)
    return candidate_module_names, verilog_module


def get_module_by_instance_path(instance_path):
    candidate_instance_paths, verilog_module = verilog_module_indexer.find_module_definition_by_instance_path(instance_path)
    return candidate_instance_paths, verilog_module


# samples of a line 
# {"_module_name":"top","_is_user_defined":"1","_file_path":"/home/tklam/development/birdie/sample_netlists/old.v","_file_begin_line_number":1,"_file_end_line_number":10,"_inputs":["a","b"],"_outputs":["c"],"_inouts":[],"_instances":[],"_submodules":[{"and":["u3","u1"]},{"or":["u2"]}]}
#{"_module_name":"nowhere","_is_user_defined":"1","_file_path":"/home/tklam/development/birdie/sample_netlists/old.v","_file_begin_line_number":12,"_file_end_line_number":14,"_inputs":["rx"],"_outputs":["tx"],"_inouts":[],"_instances":[],"_submodules":[]}


def get_design_hierarchy_str():
    hier_print = HierPrint()
    for _, t in verilog_module_indexer.top_modules.items():
        recursive_traverse_sub_instances(0, verilog_module_indexer.instance_path_2_module, t, t._module_name, hier_print)

    return str(hier_print)
