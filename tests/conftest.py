import os
import sys

_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_p = os.path.join(_root, 'collector')
if _p not in sys.path:
    sys.path.insert(0, _p)
