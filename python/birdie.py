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

from hdlConvertorAst.language import Language
from hdlConvertorAst.to.hwt import ToHwt
from hdlConvertorAst.translate.verilog_to_hwt import verilog_to_hwt
from hdlConvertor import HdlConvertor
from hdlConvertorAst.hdlAst import HdlModuleDef, HdlCompInst, HdlIdDef, HdlDirection

birdie_root_path = '../' # path to the root directory of this plugin
birdie_limit_to_use_defined_modules_default = True


verilog_module_indexer = VerilogModuleIndexer()


def init(plugin_root_path):
    global birdie_root_path
    birdie_root_path = plugin_root_path


def hello():
    print('Hello world from Birdie Verilog netlist tracer!')
    print('Env info:')
    print(' '*2 + 'Plugin path: {0}'.format(birdie_root_path))


def parse_verilog(file_path, limit_to_use_defined_modules):
    hdlConverter = HdlConvertor()
    parser_res = hdlConverter.parse(file_path, Language.VERILOG, [], debug=True)

    modules = {}

    for e in parser_res.objs:
        if not isinstance(e, HdlModuleDef):
            continue

        m : VerilogModule = None
        if e.module_name not in modules:
            m = VerilogModule()
            m._module_name = str(e.module_name)
            modules[m._module_name] = m
            m._file_path = file_path
        else:
            m = modules[e.module_name]
        m._is_user_defined = True
        m._file_begin_line_number = int(e.position.start_line)
        m._file_end_line_number = int(e.position.stop_line)

        for io in e.dec.ports:
            match io.direction:
                case HdlDirection.IN:
                    m._inputs.append(str(io.name))
                case HdlDirection.OUT:
                    m._outputs.append(str(io.name))
                case HdlDirection.INOUT:
                    m._inouts.append(str(io.name))

        for inst in [i for i in e.objs if isinstance(i, HdlCompInst)]:
            submodule = None
            if inst.module_name in modules:
                submodule = modules[inst.module_name] 
            else:
                submodule = VerilogModule()
                submodule._module_name = str(inst.module_name)
                modules[inst.module_name] = submodule
                submodule._is_user_defined = False
                submodule._file_path = file_path

            if m._instances is not None and len(m._instances) > 0:
                # has instance paths
                for p in m._instances:
                    inst_path = p + '/' + str(inst.name)
                    m._submodules.append((str(inst.name), str(inst.module_name)))
                    submodule._instances.append(inst_path)
            else:
                inst_path = m._module_name + '/' + str(inst.name)
                submodule._instances.append(inst_path)
                m._submodules.append((str(inst.name), str(inst.module_name)))

    for _, m in modules.items():
        if limit_to_use_defined_modules == '1' and not m._is_user_defined:
            print(f'Skip indexing {m._module_name} because it is not user-defined')
            continue
        if m._instances is None or len(m._instances) == 0:
            m._is_top = True
        verilog_module_indexer.index(m)


def get_module_by_line_number(file_path, line_number):
    if not verilog_module_indexer.has_index_file(file_path):
        parse_verilog(file_path, birdie_limit_to_use_defined_modules_default)

    is_exact, verilog_module_tag = verilog_module_indexer.find_module_definition_by_line_number(file_path, line_number)
    if verilog_module_tag is None:
        return None

    if len(verilog_module_tag) != 2:
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


def get_design_hierarchy_str():
    hier_print = HierPrint()
    for _, t in verilog_module_indexer.top_modules.items():
        recursive_traverse_sub_instances(0, verilog_module_indexer.instance_path_2_module, t, t._module_name, hier_print)

    return str(hier_print)
