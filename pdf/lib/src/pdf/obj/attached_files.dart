import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../document.dart';
import '../format/array.dart';
import '../format/base.dart';
import '../format/dict.dart';
import '../format/dict_stream.dart';
import '../format/indirect.dart';
import '../format/name.dart';
import '../format/num.dart';
import '../format/object_base.dart';
import '../format/stream.dart';
import '../format/string.dart';
import 'object.dart';

// ilja, custom
class AttachedFiles {

  final List<AttachedFileSpec> files = [];

  late final AttachedFileNames names;

  AttachedFiles(PdfDocument pdfDocument, Map<String, String> files,) {
    for (String fileName in files.keys) {
      String content = files[fileName]!;

      AttachedFile file = AttachedFile(
        pdfDocument,
        fileName,
        content,
      );
      this.files.add(AttachedFileSpec(
        pdfDocument,
        file,
      ));
    }
    names = AttachedFileNames(pdfDocument, this.files,);
    pdfDocument.catalog.attached = this;
  }

  PdfDict catalogNames() {
    return PdfDict(
        {
          '/EmbeddedFiles': names.ref(),
        }
    );
  }

  PdfArray catalogAF() {
    List<PdfIndirect> tmp = [];
    for (AttachedFileSpec spec in files) {
      tmp.add(spec.ref());
    }
    return PdfArray(tmp);
  }
}

class AttachedFileNames extends PdfObject<PdfDict> {

  final List<AttachedFileSpec> files;

  AttachedFileNames(PdfDocument pdfDocument, this.files,) : super(
    pdfDocument,
    params: PdfDict(),
  );

  @override
  void prepare() {
    super.prepare();
    params['/Names'] = PdfArray(
      [
        PdfRaw(0, files.first),
      ],
    );
  }
}

class AttachedFileSpec extends PdfObject<PdfDict> {
  final AttachedFile file;

  AttachedFileSpec(PdfDocument pdfDocument, this.file,) : super(
    pdfDocument,
    params: PdfDict(),
  );

  @override
  void prepare() {
    super.prepare();

    params['/Type'] = const PdfName('/Filespec');
    params['/F'] = PdfString(
      Uint8List.fromList(file.fileName.codeUnits),);
    params['/UF'] = PdfString(
      Uint8List.fromList(file.fileName.codeUnits),);
    params['/EF'] = PdfDict({
      '/F': file.ref(),
    });
    params['/AFRelationship'] = const PdfName('/Unspecified');
  }
}

class AttachedFile extends PdfObject<PdfDictStream> {

  final String fileName;
  final String content;

  AttachedFile(PdfDocument pdfDocument, this.fileName,
      this.content,) : super(
    pdfDocument,
    params: PdfDictStream(
      compress: false,
      encrypt: false,
    ),
  );

  @override
  void prepare() {
    super.prepare();

    String modDate =
    DateFormat("yyyyMMddHHmmss").format(DateTime.timestamp());
    params['/Type'] = const PdfName('/EmbeddedFile');
    params['/Subtype'] = const PdfName('/application\/octet-stream');
    params['/Params'] = PdfDict({
      '/Size': PdfNum(content.codeUnits.length),
      '/ModDate': PdfString(
        Uint8List.fromList('D:$modDate+00\'00\''.codeUnits),),
    });

    params.data = Uint8List.fromList(utf8.encode(content));
  }
}

class PdfRaw extends PdfDataType {

  final int nr;
  final AttachedFileSpec spec;

  const PdfRaw(this.nr, this.spec,);

  @override
  void output(PdfObjectBase o, PdfStream s, [int? indent]) {
    s.putString(
        '(' + nr.toString().padLeft(3, '0') + ') ' + spec.ref().toString());
  }
}