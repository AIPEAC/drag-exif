class ExifTagItem {
  final int index;
  final String tagId;
  final String tagGroup;
  final String tagName;
  final String tagValue;

  const ExifTagItem({
    required this.index,
    required this.tagId,
    required this.tagGroup,
    required this.tagName,
    required this.tagValue,
  });

  Map<String, dynamic> toJson() => {
        'Index': index,
        'TagGroup': tagGroup,
        'TagId': tagId,
        'TagName': tagName,
        'TagValue': tagValue,
      };
}

enum ExportFileType { text, csv, json }
