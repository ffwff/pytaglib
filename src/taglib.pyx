# -*- coding: utf-8 -*-
# distutils: language = c++
# cython: language_level = 3
# Copyright 2018 Michael Helmling, michaelhelmling@posteo.de
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

from libcpp.utility cimport pair
cimport ctypes
from cpython.bytes cimport PyBytes_FromStringAndSize

version = '1.4.4'

cdef unicode toUnicode(ctypes.String s):
    """Converts TagLib::String to a unicode string (``str`` in Python 3, ``unicode`` else)."""
    return s.to8Bit(True).decode('UTF-8', 'replace')

cdef bytes toBytearray(ctypes.ByteVector v):
    return PyBytes_FromStringAndSize(v.data(), v.size())

cdef dict propertyMapToDict(ctypes.PropertyMap map):
    """Convert a TagLib::PropertyMap to a dict mapping unicode string to list of unicode strings."""
    cdef:
        ctypes.StringList values
        pair[ctypes.String, ctypes.StringList] mapIter
        dict dct = {}
        str tag
    for mapIter in map:
        tag = toUnicode(mapIter.first)
        dct[tag] = []
        values = mapIter.second
        for value in values:
            dct[tag].append(toUnicode(value))
    return dct

class Picture:

    def __init__(self, mimetype, data):
        self.mimetype = mimetype
        self.data = data

cdef class File:
    """Class representing an audio file with metadata ("tags").

    To read tags from an audio file, create a *File* object, passing the file's path to the
    constructor (should be a unicode string):

    >>> f = taglib.File('/path/to/file.ogg')

    The tags are stored in the attribute *tags* as a *dict* mapping strings (tag names)
    to lists of strings (tag values).

    >>> for tag, values in f:
    >>>     print('{}->{}'.format(tag, ', '.join(values)))

    If the file contains some metadata that is not supported by pytaglib or not representable
    as strings (e.g. cover art, proprietary data written by some programs, ...), according
    identifiers will be placed into the *unsupported* attribute of the File object. Using the
    method *removeUnsupportedProperties*, some or all of those can be removed.

    Additionally, the readonly attributes *length*, *bitrate*, *sampleRate*, and *channels* are
    available with their obvious meanings.

    >>> print('File length: {}'.format(f.length))

    Changes to the *tags* attribute are stored using the *save* method.

    >>> f.save()
    """
    cdef ctypes.File *cFile
    cdef public dict tags
    cdef bytes bPath
    cdef readonly object path
    cdef readonly list unsupported

    def __cinit__(self, path):
        if not isinstance(path, unicode):
            path = path.decode('utf8')
        self.path = path
        self.bPath = path.encode('utf8')
        IF UNAME_SYSNAME == "Windows":
            # create on windows takes wchar_t* which Cython automatically converts to
            # from unicode strings
            self.cFile = ctypes.create(self.path)
        ELSE:
            self.cFile = ctypes.create(self.bPath)
        if not self.cFile or not self.cFile.isValid():
            raise OSError(f'Could not read file {path}')

    def __init__(self, path):
        self.tags = dict()
        self.unsupported = list()
        self.readProperties()

    cdef void readProperties(self):
        """Convert the Taglib::PropertyMap of the wrapped Taglib::File object into a python dict.

        This method is not accessible from Python, and is called only once, immediately after
        object creation.
        """

        cdef:
            ctypes.PropertyMap cTags = self.cFile.properties()
            ctypes.String cString
            ctypes.StringList unsupported
        self.tags = propertyMapToDict(cTags)
        unsupported = cTags.unsupportedData()
        for cString in unsupported:
            self.unsupported.append(toUnicode(cString))

    def save(self):
        """Store the tags currently hold in the `tags` attribute into the file.

        If some tags cannot be stored because the underlying metadata format does not support them,
        the unsuccesful tags are returned as a "sub-dictionary" of `self.tags` which will be empty
        if everything is ok.

        Raises
        ------
        OSError
            If the save operation fails completely (file does not exist, insufficient rights, ...).
        ValueError
            When attempting to save after the file was closed.
        """
        if not self.cFile:
            raise ValueError('I/O operation on closed file.')
        if self.readOnly:
            raise OSError(f'Unable to save tags: file is read-only')
        cdef:
            ctypes.PropertyMap cTagdict, cRemaining
            ctypes.String cKey, cValue

        # populate cTagdict with the contents of self.tags
        for key, values in self.tags.items():
            if isinstance(key, bytes):
                cKey = ctypes.String(key.upper(), ctypes.UTF8)
            else:
                cKey = ctypes.String(key.upper().encode('UTF-8'), ctypes.UTF8)
            if isinstance(values, bytes) or isinstance(values, unicode):
                # the user has accidentally used a single tag value instead a length-1 list
                values = [ values ]
            for value in values:
                if isinstance(value, bytes):
                    cValue = ctypes.String(value, ctypes.UTF8)
                else:
                    cValue = ctypes.String(value.encode('UTF-8'), ctypes.UTF8)
                cTagdict[cKey].append(cValue)

        cRemaining = self.cFile.setProperties(cTagdict)
        success = self.cFile.save()
        if not success:
            raise OSError('Unable to save tags: Unknown OS error')
        return propertyMapToDict(cRemaining)

    def removeUnsupportedProperties(self, properties):
        """This is a direct binding for the corresponding TagLib method."""
        if not self.cFile:
            raise ValueError('I/O operation on closed file.')
        cdef ctypes.StringList cProps
        for value in properties:
            cProps.append(ctypes.String(value.encode('UTF-8'), ctypes.UTF8))
        self.cFile.removeUnsupportedProperties(cProps)

    def close(self):
        """Closes the file by deleting the underlying Taglib::File object. This will close any open
        streams. Calling methods like `save()` or the read-only properties after `close()` will
        raise an exception."""
        del self.cFile
        self.cFile = NULL

    def __dealloc__(self):
        if self.cFile:
            del self.cFile

    property length:
        def __get__(self):
            if not self.cFile:
                raise ValueError('I/O operation on closed file.')
            return self.cFile.audioProperties().length()

    property bitrate:
        def __get__(self):
            if not self.cFile:
                raise ValueError('I/O operation on closed file.')
            return self.cFile.audioProperties().bitrate()

    property sampleRate:
        def __get__(self):
            if not self.cFile:
                raise ValueError('I/O operation on closed file.')
            return self.cFile.audioProperties().sampleRate()

    property channels:
        def __get__(self):
            if not self.cFile:
                raise ValueError('I/O operation on closed file.')
            return self.cFile.audioProperties().channels()

    property readOnly:
        def __get__(self):
            if not self.cFile:
                raise ValueError('I/O operation on closed file.')
            return self.cFile.readOnly()

    property picture:
        def __get__(self):
            cdef:
                # mpeg
                ctypes.MPEGFile *mpegFile
                ctypes.ID3v2Tag *mpegTag
                ctypes.ID3v2AttachedPictureFrame *mpegCover
                # mp4
                ctypes.MP4File *mp4File
                ctypes.MP4Tag *mp4Tag
                ctypes.MP4CoverArtList mp4CoverList
                # flac
                ctypes.FLACFile *flacFile
                ctypes.FLACPicture *flacCover
            if self.path.endswith(".mp3"):
                mpegFile = <ctypes.MPEGFile *> self.cFile
                mpegTag = mpegFile.ID3v2Tag(False)
                if mpegTag != NULL:
                    mpegCover = <ctypes.ID3v2AttachedPictureFrame *> mpegTag.frameList("APIC").front()
                    if mpegCover != NULL:
                        return Picture(toUnicode(mpegCover.mimeType()),
                                       toBytearray(mpegCover.picture()))
            elif self.path.endswith(".mp4") or self.path.endswith(".m4a"):
                mp4File = <ctypes.MP4File *> self.cFile
                mp4Tag = mp4File.tag()
                if mp4Tag != NULL:
                    mp4CoverList = mp4Tag.itemMap()[ctypes.String("covr", ctypes.Type.UTF8)].toCoverArtList()
                    if not mp4CoverList.isEmpty():
                        mimeformat = mp4CoverList.front().format()
                        if mimeformat == ctypes.MP4CoverArtFormat.JPEG:
                            mimetype = "image/jpg"
                        elif mimeformat == ctypes.MP4CoverArtFormat.PNG:
                            mimetype = "image/png"
                        elif mimeformat == ctypes.MP4CoverArtFormat.BMP:
                            mimetype = "image/bmp"
                        elif mimeformat == ctypes.MP4CoverArtFormat.GIF:
                            mimetype = "image/gif"
                        else:
                            mimetype = ""
                        data = mp4CoverList.front().data()
                        return Picture(mimetype, toBytearray(data))
            elif self.path.endswith(".flac"):
                flacFile = <ctypes.FLACFile *> self.cFile
                if not flacFile.pictureList().isEmpty():
                    flacCover = flacFile.pictureList().front()
                    if flacCover != NULL:
                        return Picture(toUnicode(flacCover.mimeType()),
                                       toBytearray(flacCover.data()))
            return None

    def __repr__(self):
        return f"File('{self.path}')"
