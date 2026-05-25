/*
DragExif - EXIF metadata viewer
Copyright (C) 2026 Allen
Project homepage: https://github.com/AIPEAC/drag-exif


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import '../models/exif_tag_definition.dart';

class ExifTagCatalog {
  static final List<ExifTagDefinition> _tags = _buildCatalog();

  static List<ExifTagDefinition> get allTags => List.unmodifiable(_tags);

  static List<ExifTagDefinition> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return allTags;
    return _tags.where((t) {
      return t.tagName.toLowerCase().contains(q) ||
          t.group.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  static List<ExifTagDefinition> _buildCatalog() {
    return [
      // ── EXIF (Image) ──
      const ExifTagDefinition(tagName: 'ImageDescription', group: 'EXIF', description: 'Image description'),
      const ExifTagDefinition(tagName: 'Make', group: 'EXIF', description: 'Camera manufacturer'),
      const ExifTagDefinition(tagName: 'Model', group: 'EXIF', description: 'Camera model'),
      const ExifTagDefinition(tagName: 'Orientation', group: 'EXIF', description: 'Image orientation'),
      const ExifTagDefinition(tagName: 'XResolution', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'YResolution', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ResolutionUnit', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Software', group: 'EXIF', description: 'Software used'),
      const ExifTagDefinition(tagName: 'DateTime', group: 'EXIF', description: 'File modification date/time'),
      const ExifTagDefinition(tagName: 'Artist', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Copyright', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'UserComment', group: 'EXIF'),

      // ── EXIF (Camera settings) ──
      const ExifTagDefinition(tagName: 'ExposureTime', group: 'EXIF', description: 'Shutter speed'),
      const ExifTagDefinition(tagName: 'FNumber', group: 'EXIF', description: 'Aperture f-number'),
      const ExifTagDefinition(tagName: 'ExposureProgram', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ISOSpeedRatings', group: 'EXIF', description: 'ISO sensitivity'),
      const ExifTagDefinition(tagName: 'ISO', group: 'EXIF', description: 'ISO sensitivity'),
      const ExifTagDefinition(tagName: 'DateTimeOriginal', group: 'EXIF', description: 'Date/time original'),
      const ExifTagDefinition(tagName: 'CreateDate', group: 'EXIF', description: 'Date/time digitized'),
      const ExifTagDefinition(tagName: 'ModifyDate', group: 'EXIF', description: 'Date/time modified'),
      const ExifTagDefinition(tagName: 'OffsetTime', group: 'EXIF', description: 'Time zone offset'),
      const ExifTagDefinition(tagName: 'OffsetTimeOriginal', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'OffsetTimeDigitized', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ShutterSpeedValue', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ApertureValue', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'BrightnessValue', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ExposureCompensation', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'MaxApertureValue', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'SubjectDistance', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'MeteringMode', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'LightSource', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Flash', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'FocalLength', group: 'EXIF', description: 'Lens focal length'),
      const ExifTagDefinition(tagName: 'SubSecTime', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'SubSecTimeOriginal', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'SubSecTimeDigitized', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ColorSpace', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ExifImageWidth', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ExifImageHeight', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'FocalPlaneXResolution', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'FocalPlaneYResolution', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'FocalPlaneResolutionUnit', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'SensingMethod', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'CustomRendered', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'ExposureMode', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'WhiteBalance', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'DigitalZoomRatio', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'FocalLengthIn35mmFormat', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'SceneCaptureType', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'GainControl', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Contrast', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Saturation', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Sharpness', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'SubjectDistanceRange', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'LensMake', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'LensModel', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'LensSerialNumber', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'LensInfo', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'Lens', group: 'EXIF'),
      const ExifTagDefinition(tagName: 'LensID', group: 'EXIF'),

      // ── GPS ──
      const ExifTagDefinition(tagName: 'GPSLatitudeRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSLatitude', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSLongitudeRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSLongitude', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSAltitudeRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSAltitude', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSTimeStamp', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSSatellites', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSStatus', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSMeasureMode', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDOP', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSSpeedRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSSpeed', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSTrackRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSTrack', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSImgDirectionRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSImgDirection', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSMapDatum', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestLatitudeRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestLatitude', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestLongitudeRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestLongitude', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestBearingRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestBearing', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestDistanceRef', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDestDistance', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSProcessingMethod', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSAreaInformation', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDateStamp', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSDifferential', group: 'GPS'),
      const ExifTagDefinition(tagName: 'GPSHPositioningError', group: 'GPS'),

      // ── IPTC ──
      const ExifTagDefinition(tagName: 'By-line', group: 'IPTC', description: 'Creator'),
      const ExifTagDefinition(tagName: 'By-lineTitle', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Caption-Abstract', group: 'IPTC', description: 'Caption'),
      const ExifTagDefinition(tagName: 'Writer-Editor', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Headline', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Credit', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Source', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'CopyrightNotice', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Contact', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Keywords', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'ContentLocationCode', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'ContentLocationName', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Category', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'SupplementalCategories', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'DateCreated', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'TimeCreated', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'City', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Sub-location', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Province-State', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Country-PrimaryLocationCode', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Country-PrimaryLocationName', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'OriginalTransmissionReference', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'SpecialInstructions', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'Urgency', group: 'IPTC'),
      const ExifTagDefinition(tagName: 'ObjectName', group: 'IPTC'),

      // ── XMP (dc) ──
      const ExifTagDefinition(tagName: 'Title', group: 'XMP-dc'),
      const ExifTagDefinition(tagName: 'Description', group: 'XMP-dc'),
      const ExifTagDefinition(tagName: 'Creator', group: 'XMP-dc'),
      const ExifTagDefinition(tagName: 'Rights', group: 'XMP-dc'),
      const ExifTagDefinition(tagName: 'Subject', group: 'XMP-dc', description: 'Keywords'),

      // ── XMP (xmp) ──
      const ExifTagDefinition(tagName: 'XMPToolkit', group: 'XMP-xmp'),
      const ExifTagDefinition(tagName: 'CreatorTool', group: 'XMP-xmp', description: 'Software'),
      const ExifTagDefinition(tagName: 'CreateDate', group: 'XMP-xmp'),
      const ExifTagDefinition(tagName: 'ModifyDate', group: 'XMP-xmp'),
      const ExifTagDefinition(tagName: 'Rating', group: 'XMP-xmp'),
      const ExifTagDefinition(tagName: 'Label', group: 'XMP-xmp'),

      // ── XMP (photoshop) ──
      const ExifTagDefinition(tagName: 'City', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'State', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Country', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Headline', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Credit', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Source', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Instructions', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'TransmissionReference', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Category', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'SupplementalCategories', group: 'XMP-photoshop'),
      const ExifTagDefinition(tagName: 'Urgency', group: 'XMP-photoshop'),

      // ── XMP (Iptc4xmpCore) ──
      const ExifTagDefinition(tagName: 'Location', group: 'XMP-iptcCore'),
      const ExifTagDefinition(tagName: 'CountryCode', group: 'XMP-iptcCore'),
      const ExifTagDefinition(tagName: 'CreatorWorkEmail', group: 'XMP-iptcCore'),
      const ExifTagDefinition(tagName: 'CreatorWorkURL', group: 'XMP-iptcCore'),

      // ── XMP (Iptc4xmpExt) ──
      const ExifTagDefinition(tagName: 'PersonInImage', group: 'XMP-iptcExt'),
      const ExifTagDefinition(tagName: 'Event', group: 'XMP-iptcExt'),
      const ExifTagDefinition(tagName: 'OrganInImage', group: 'XMP-iptcExt'),
      const ExifTagDefinition(tagName: 'WorldRegion', group: 'XMP-iptcExt'),
      const ExifTagDefinition(tagName: 'Sublocation', group: 'XMP-iptcExt'),

      // ── ICC_Profile ──
      const ExifTagDefinition(tagName: 'ProfileCopyright', group: 'ICC_Profile'),
      const ExifTagDefinition(tagName: 'ProfileDescription', group: 'ICC_Profile'),
      const ExifTagDefinition(tagName: 'ProfileCopyright', group: 'ICC_Profile'),

      // ── File ──
      const ExifTagDefinition(tagName: 'FileModifyDate', group: 'File'),
      const ExifTagDefinition(tagName: 'FileAccessDate', group: 'File'),
      const ExifTagDefinition(tagName: 'FileCreateDate', group: 'File'),
    ];
  }
}
