# -*- coding: utf-8 -*-
# Copyright 2011-2012 Michael Helmling, helmling@mathematik.uni-kl.de
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

cimport ctypes, cython
#from ctypes2 cimport listiter, mapiter
from cython.operator cimport dereference as deref, preincrement as inc


@cython.final
cdef class File:
    """Wrapper class for an audio file with metadata.
    
    To read tags from an audio file, simply create a *File* object, passing the file's
    path to the constructor:
    
    f = taglib.File("/path/to/file.ogg")
    
    The tags are stored in the attribute *tags* as a *dict* mapping strings (tag names)
    to lists of strings (tag values).
    
    Additionally, the attributes "length", "bitrate", "sampleRate", and "channels" are
    available.
    
    Changes to the *tags* attribute are saved using the *save* method, which returns a
    bool value indicating success.
    
    Information about tags which are not representable by the "tag name"->"list of values"
    model is stored in the attribute *unsupported*, which is a list of strings. For example,
    in case of ID3 tags, the list contains the ID3 frame IDs of unsupported frames. Such
    unsupported metadata can be removed by passing (a subset of) the *unsupported* list
    to *removeUnsupportedProperties*. See the TagLib documentation for details. 
    """
    
    # private C attributes, not visible from within Python
    cdef ctypes.File *_f
    cdef public object tags
    cdef public object unsupported
    cdef public object path
    def __cinit__(self, path):        
        b = path.encode()
        self._f = ctypes.create(b)
        if not self._f or not self._f.isValid():
            raise OSError('Could not read file "{0}"'.format(path))
        
    def __init__(self, path):
        """Create a new File for the given path, which must exist. Immediately reads metadata."""
        self.tags = dict()
        self.unsupported = list()
        self.path = path
        self._read()
    
    cdef _read(self):
        """Convert the PropertyMap of the wrapped File* object into a python dict.
        
        This method is not accessible from Python, and is called only once, immediately after
        object creation."""
        cdef ctypes.PropertyMap _tags = self._f.properties()
        cdef ctypes.mapiter it = _tags.begin()
        cdef ctypes.StringList values
        cdef ctypes.listiter lit
        cdef ctypes.String s
        while it != _tags.end(): # iterate through the keys of the PropertyMap
            s = deref(it).first # for some reason, <ctypes.pair[...]>deref(it) does not work (bug in Cython?)
            tag = s.toCString(True).decode('UTF-8') # this isn't pretty, but it works
            self.tags[tag] = []
            values = deref(it).second
            lit = values.begin()
            while lit != values.end():
                self.tags[tag].append((<ctypes.String>deref(lit)).toCString(True).decode('UTF-8','replace'))
                inc(lit)
            inc(it)
            
        lit = _tags.unsupportedData().begin()
        while lit != _tags.unsupportedData().end():
            s = deref(lit)
            self.unsupported.append(s.toCString(True).decode('UTF-8'))
            inc(lit)
    
    def save(self):
        """Store the tags currently hold in the *tags* attribute into the file. Returns a boolean
        flag which indicates success."""
        if self.readOnly:
            raise OSError('Unable to write tags: file "{0}" is not writable'.format(self.path))
        cdef ctypes.PropertyMap _tagdict
        cdef ctypes.String s1, s2
        cdef ctypes.Type typ = ctypes.UTF8
        for key, values in self.tags.items():
            x = key.upper().encode() # needed to satisfy Cython; since the String() constructor copies the data, no memory problems should arise here
            s1 = ctypes.String(x,typ)
            if isinstance(values, str):
                values = [ values ]
            for value in values:
                x = value.encode()
                s2 = ctypes.String(x, typ)
                _tagdict[s1].append(s2)
        self._f.setProperties(_tagdict)
        return self._f.save()
    
    def removeUnsupportedProperties(self, properties):
        """This is a direct binding for the corresponding TagLib method."""
        cdef ctypes.StringList _props
        cdef ctypes.String s
        cdef ctypes.Type typ = ctypes.UTF8
        for value in properties:
            x = value.encode()
            s = ctypes.String(x, typ)
            _props.append(s)
        self._f.removeUnsupportedProperties(_props)
        
    def __dealloc__(self):
        del self._f       
        
    property length:
        def __get__(self):
            return self._f.audioProperties().length()
            
    property bitrate:
        def __get__(self):
            return self._f.audioProperties().bitrate()
    
    property sampleRate:
        def __get__(self):
            return self._f.audioProperties().sampleRate()
            
    property channels:
        def __get__(self):
            return self._f.audioProperties().channels()
    
    property readOnly:
        def __get__(self):
            return self._f.readOnly()