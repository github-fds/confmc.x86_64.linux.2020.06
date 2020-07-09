#!/usr/bin/env python
# -*- coding: utf8 -*-
"""
Python version numbers and their encoding ("magic number").
It reads two-byte out of four-byte magic number of pyc or pyo.
Structure 'pyc' file:
    A four-byte magic number,
    A four-byte modification timestamp, and
    A marshalled code object.
"""
from __future__ import print_function

__author__     = "Ando Ki"
__copyright__  = "Copyright 2020, Future Design Systems"
__credits__    = ["none", "some"]
__license__    = "FUTURE DESIGN SYSTEMS SOFTWARE END-USER LICENSE AGREEMENT FOR CON-FMC."
__version__    = "1"
__revision__   = "0"
__maintainer__ = "Ando Ki"
__email__      = "contact@future-ds.com"
__status__     = "Development"
__date__       = "2020.07.09"
__description__= "Python PYC/PYO version from magic number"

import os
import sys
import struct
import getopt

# These constants are from Python-3.x.x/Lib/importlib/_bootstrap_external.py
MAGICS = {
    20121: '1.5.x',
    50428: '1.6',
    50823: '2.0.x',
    60202: '2.1.x',
    60717: '2.2',
    62011: '2.3a0',
    62021: '2.3a0',
    62041: '2.4a0',
    62051: '2.4a3',
    62061: '2.4b1',
    62071: '2.5a0',
    62081: '2.5a0',
    62091: '2.5a0',
    62092: '2.5a0',
    62101: '2.5b3',
    62111: '2.5b3',
    62121: '2.5c1',
    62131: '2.5c2',
    62151: '2.6a0',
    62161: '2.6a1',
    62171: '2.7a0',
    62181: '2.7a0',
    62191: '2.7a0',
    62201: '2.7a0',
    62211: '2.7a0',
    3000: '3000',
    3010: '3000',
    3020: '3000',
    3030: '3000',
    3040: '3000',
    3050: '3000',
    3060: '3000',
    3061: '3000',
    3071: '3000',
    3081: '3000',
    3091: '3000',
    3101: '3000',
    3103: '3000',
    3111: '3.0a4',
    3131: '3.0a5',
    3141: '3.1a0',
    3151: '3.1a0',
    3160: '3.2a0',
    3170: '3.2a1',
    3180: '3.2a2',
    3190: '3.3a0',
    3200: '3.3a0',
    3210: '3.3a0',
    3220: '3.3a1',
    3230: '3.3a4',
    3250: '3.4a1',
    3260: '3.4a1',
    3270: '3.4a1',
    3280: '3.4a1',
    3290: '3.4a4',
    3300: '3.4a4',
    3310: '3.4rc2',
    3320: '3.5a0',
    3330: '3.5b1',
    3340: '3.5b2',
    3350: '3.5b2',
    3360: '3.6a0',
    3361: '3.6a0',
    3370: '3.6a1',
    3371: '3.6a1',
    3372: '3.6a1',
    3373: '3.6b1',
    3375: '3.6b1',
    3376: '3.6b1',
    3377: '3.6b1',
    3378: '3.6b2',
    3379: '3.6rc1',
    3390: '3.7a1',
    3391: '3.7a2',
    3392: '3.7a4',
    3393: '3.7b1',
    3394: '3.7b5',
    3400: '3.8a1',
    3401: '3.8a1',
    3410: '3.8a1',
    3411: '3.8b2',
    3412: '3.8b2',
    3413: '3.8b4',
    3420: '3.9a0',
    3421: '3.9a0',
    3422: '3.9a0',
    3423: '3.9a2',
    3424: '3.9a2',
    3425: '3.9a2',   
}

def get_compiled_file_python_version(filename):
    """Get the version of Python by which the file was compiled"""
    ext = os.path.splitext(filename)[1]
    if ext not in ['.pyc', '.pyo']:
        print('Please select *.pyc or *.pyo files')
        return ''
    if not os.path.isfile(filename):
        print('File "%s" doesn\'t exist' % filename)
        return ''
    with open(filename, 'rb') as in_file:
        magic = in_file.read(4)
        magic_data = struct.unpack('H2B', magic)
        python_version = MAGICS.get(magic_data[0], '')
        if magic_data[1:] != (13, 10):
            magic_hex = binascii.hexlify(magic).decode()
            print('Wrong magic bytes "%s". Last two bytes must be "0d0a"!' % magic_hex)
            return ''
        if not python_version:
            print('Unknown Python version or wrong magic bytes!')
    return python_version

def get_compiled_file_python_version_old(filename):
    """
    Get the version of Python by which the file was compiled
    """
    name, ext = os.path.splitext(filename)
    if ext not in ['.pyc', '.pyo']:
        print('Please select *.pyc or *.pyo files')
        return ''
    if not os.path.isfile(filename):
        print('File "%s" doesn\'t exist' % filename)
        return ''
    with open(filename, 'rb') as f:
        magic = f.read(4)
        magic_data = struct.unpack('H2B', magic)
        python_version = MAGICS.get(magic_data[0], '')
        if magic_data[1:] != (13, 10):
            print('Wrong magic bytes: %s' % magic.encode('hex'))
            return ''
        if not python_version:
            print('Unknown Python version or wrong magic bytes')
    return python_version

def help(prog):
    print(prog+' [-h]' + 'pyc_or_pyo_files')

def main(prog, argv):
    try: opts, args = getopt.getopt(argv, "h", ['help'])
    except getopt.GetoptError:
           help(prog)
           sys.exit(2)
    for opt, arg in opts:
        if opt=='-h': help(prog); sys.exit()
        else: print("unknown options: "+str(opt)); exit(1)
    for pyc_pyo in args:
        python_version = get_compiled_file_python_version(pyc_pyo)
        if python_version:
           print('File "%s" is compiled with: %s' % (pyc_pyo, python_version))

if __name__ == '__main__':
    main(sys.argv[0], sys.argv[1:]);

# Revision history:
#
# 2020.07.09: started by Ando Ki
#             ref: https://gist.githubusercontent.com/helix84/f14b5516ea501ee220013d7a63db560b/raw/2a037242015bcd747f6b8e501d425dfbed2b20d0/compiled_file_python_version.py
#             ref: https://gist.github.com/delimitry/bad5496b52161449f6de
