# -*- coding: utf-8 -*-
# Copyright 2011-2018 Michael Helmling, michaelhelmling@posteo.de
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

"""This file contains the external C/C++ definitions used by taglib.pyx."""

from libcpp.list cimport list
from libcpp.string cimport string
from libcpp.map cimport map
from libc.stddef cimport wchar_t

cdef extern from 'taglib/tstring.h' namespace 'TagLib::String':
    cdef extern enum Type:
        Latin1, UTF16, UTF16BE, UTF8, UTF16LE


cdef extern from 'taglib/tstring.h' namespace 'TagLib':
    cdef cppclass String:
        String()
        String(char*, Type)
        string to8Bit(bint)

cdef extern from 'taglib/tbytevector.h' namespace 'TagLib':
    cdef cppclass ByteVector:
        char *data()
        unsigned int size()

cdef extern from 'taglib/tstringlist.h' namespace 'TagLib':
    cdef cppclass StringList:
        list[String].iterator begin()
        list[String].iterator end()
        void append(String&)


cdef extern from 'taglib/tpropertymap.h' namespace 'TagLib':
    cdef cppclass PropertyMap:
        map[String,StringList].iterator begin()
        map[String,StringList].iterator end()
        StringList& operator[](String&)
        StringList& unsupportedData()
        int size()


cdef extern from 'taglib/audioproperties.h' namespace 'TagLib':
    cdef cppclass AudioProperties:
        int length()
        int bitrate()
        int sampleRate()
        int channels()


cdef extern from 'taglib/tfile.h' namespace 'TagLib':
    cdef cppclass File:
        AudioProperties *audioProperties()
        bint save() except +
        bint isValid()
        bint readOnly()
        PropertyMap properties()
        PropertyMap setProperties(PropertyMap&)
        void removeUnsupportedProperties(StringList&)

cdef extern from 'taglib/fileref.h' namespace 'TagLib::FileRef':
    IF UNAME_SYSNAME == "Windows":
        cdef File* create(const Py_UNICODE*) except +
    ELSE:
        cdef File* create(const char*) except +

# mpeg (.mp3 files)
cdef extern from 'taglib/attachedpictureframe.h' namespace 'TagLib::ID3v2':
    cdef cppclass ID3v2AttachedPictureFrame 'TagLib::ID3v2::AttachedPictureFrame':
        String mimeType()
        ByteVector picture()

cdef extern from 'taglib/id3v2tag.h' namespace 'TagLib::ID3v2':
    cdef cppclass ID3v2Frame 'TagLib::ID3v2::Frame':
        pass

    cdef cppclass ID3v2Tag 'TagLib::ID3v2::Tag':
        list[ID3v2Frame*] frameList(const char *)

cdef extern from 'taglib/mpegfile.h' namespace 'TagLib::MPEG':
    cdef cppclass MPEGFile 'TagLib::MPEG::File':
        ID3v2Tag *ID3v2Tag(bint)

# m4a (.m4a, .mp4 files)
cdef extern from 'taglib/mp4coverart.h' namespace 'TagLib::MP4::CoverArt':
    cdef enum MP4CoverArtFormat 'TagLib::MP4::CoverArt::Format':
        JPEG, PNG, BMP, GIF, Unknown

    cdef cppclass MP4CoverArt 'TagLib::MP4::CoverArt':
        MP4CoverArtFormat format()
        ByteVector data()

    cdef cppclass MP4CoverArtList 'TagLib::MP4::CoverArtList':
        MP4CoverArt front()
        bint isEmpty()

cdef extern from 'taglib/mp4item.h' namespace 'TagLib::MP4':
    cdef cppclass MP4Item 'TagLib::MP4::Item':
        MP4CoverArtList toCoverArtList()

cdef extern from 'taglib/mp4tag.h' namespace 'TagLib::MP4':
    cdef cppclass MP4Tag 'TagLib::MP4::Tag':
        map[String, MP4Item] itemMap()


cdef extern from 'taglib/mp4file.h' namespace 'TagLib::MP4':
    cdef cppclass MP4File 'TagLib::MP4::File':
        MP4Tag *tag()

# flac (.flac files)
cdef extern from 'taglib/flacpicture.h' namespace 'TagLib::FLAC':
    cdef cppclass FLACPicture 'TagLib::FLAC::Picture':
        String mimeType()
        ByteVector data()

    cdef cppclass FLACPictureList 'TagLib::FLAC::PictureList':
        bint isEmpty()
        FLACPicture *front()

cdef extern from 'taglib/flacfile.h' namespace 'TagLib::FLAC':
    cdef cppclass FLACFile 'TagLib::FLAC::File':
        FLACPictureList pictureList()
