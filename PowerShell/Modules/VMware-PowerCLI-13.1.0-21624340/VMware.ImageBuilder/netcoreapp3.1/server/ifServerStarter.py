#######################################################################
# Copyright (C) 2023 VMWare, Inc.
# All Rights Reserved
#######################################################################
"""Image Factory Server Starter"""

import sys
import os

SUPPORTED_PYTHON_VERSIONS = (
   "python-37", "python-38",
   "python-39", "python-310",
   "python-311")

SERVER_DIR = os.path.abspath(os.path.dirname(__file__))
PYTHON_DIST = "python-{major}{minor}".format(major=sys.version_info.major,
                                             minor=sys.version_info.minor)

if PYTHON_DIST not in SUPPORTED_PYTHON_VERSIONS:
   # Error code 5 stands for an attempt to start if-server with an
   # unsupported Python version.
   # ImageBuilder supports python versions 3.7 through to 3.11.
   #
   # Code needs to be in sync with IfServer.cs.
   sys.exit(5)

PYTHON_DIR = os.path.join(SERVER_DIR, PYTHON_DIST)
if PYTHON_DIR not in sys.path:
   sys.path.append(PYTHON_DIR)

import ifServer

def main(args):
   ifServer.main(args)

if __name__ == "__main__":
    main(sys.argv)

