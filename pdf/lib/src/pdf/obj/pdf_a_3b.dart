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

class AttachedFiles {

  AttachedFiles(
    PdfDocument pdfDocument,
    Map<String, String> files,
  ) {
    for (var fileName in files.keys) {
      final content = files[fileName]!;

      final file = AttachedFile(
        pdfDocument,
        fileName,
        content,
      );
      this.files.add(AttachedFileSpec(
            pdfDocument,
            file,
          ));
    }
    names = AttachedFileNames(
      pdfDocument,
      this.files,
    );
    pdfDocument.catalog.attached = this;
  }
  final List<AttachedFileSpec> files = [];

  late final AttachedFileNames names;

  PdfDict catalogNames() {
    return PdfDict({
      '/EmbeddedFiles': names.ref(),
    });
  }

  PdfArray catalogAF() {
    final tmp = <PdfIndirect>[];
    for (var spec in files) {
      tmp.add(spec.ref());
    }
    return PdfArray(tmp);
  }
}

class AttachedFileNames extends PdfObject<PdfDict> {

  AttachedFileNames(
    PdfDocument pdfDocument,
    this.files,
  ) : super(
          pdfDocument,
          params: PdfDict(),
        );
  final List<AttachedFileSpec> files;

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

  AttachedFileSpec(
    PdfDocument pdfDocument,
    this.file,
  ) : super(
          pdfDocument,
          params: PdfDict(),
        );
  final AttachedFile file;

  @override
  void prepare() {
    super.prepare();

    params['/Type'] = const PdfName('/Filespec');
    params['/F'] = PdfString(
      Uint8List.fromList(file.fileName.codeUnits),
    );
    params['/UF'] = PdfString(
      Uint8List.fromList(file.fileName.codeUnits),
    );
    params['/EF'] = PdfDict({
      '/F': file.ref(),
    });
    params['/AFRelationship'] = const PdfName('/Unspecified');
  }
}

class AttachedFile extends PdfObject<PdfDictStream> {

  AttachedFile(
    PdfDocument pdfDocument,
    this.fileName,
    this.content,
  ) : super(
          pdfDocument,
          params: PdfDictStream(
            compress: false,
            encrypt: false,
          ),
        );

  final String fileName;
  final String content;

  @override
  void prepare() {
    super.prepare();

    String modDate = DateFormat("yyyyMMddHHmmss").format(DateTime.now());
    params['/Type'] = const PdfName('/EmbeddedFile');
    params['/Subtype'] = const PdfName('/application/octet-stream');
    params['/Params'] = PdfDict({
      '/Size': PdfNum(content.codeUnits.length),
      '/ModDate': PdfString(
        Uint8List.fromList('D:$modDate+00\'00\''.codeUnits),
      ),
    });

    params.data = Uint8List.fromList(utf8.encode(content));
  }
}

class PdfRaw extends PdfDataType {

  const PdfRaw(
    this.nr,
    this.spec,
  );
  final int nr;
  final AttachedFileSpec spec;

  @override
  void output(PdfObjectBase o, PdfStream s, [int? indent]) {
    s.putString(
        '(${nr.toString().padLeft(3, '0')}) ${spec.ref()}');
  }
}

// ilja, custom
class ColorProfile extends PdfObject<PdfDictStream> {

  ColorProfile(
    PdfDocument pdfDocument,
    this.icc,
  ) : super(
          pdfDocument,
          params: PdfDictStream(
            compress: false,
            encrypt: false,
          ),
        ) {
    pdfDocument.catalog.colorProfile = this;
  }
  final Uint8List icc;

  @override
  void prepare() {
    super.prepare();
    params['/N'] = const PdfNum(3);
    params.data = icc;
  }

  PdfArray outputIntents() {
    return PdfArray<PdfDict>([
      PdfDict({
        '/Type': const PdfName('/OutputIntent'),
        '/S': const PdfName('/GTS_PDFA1'),
        '/OutputConditionIdentifier':
            PdfString(Uint8List.fromList('sRGB2014.icc'.codeUnits)),
        '/Info': PdfString(Uint8List.fromList('sRGB2014.icc'.codeUnits)),
        '/RegistryName':
            PdfString(Uint8List.fromList('http://www.color.org'.codeUnits)),
        '/DestOutputProfile': ref(),
      }),
    ]);
  }
}
