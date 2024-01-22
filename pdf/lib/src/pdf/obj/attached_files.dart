import 'package:xml/xml.dart';

import '../document.dart';
import '../format/dict_stream.dart';
import 'object.dart';

// ilja, custom
class AttachedFiles extends PdfObject<PdfDictStream> {
  final XmlDocument zugferd;

  AttachedFiles(
    PdfDocument pdfDocument,
    this.zugferd,
  ) : super(
          pdfDocument,
          params: PdfDictStream(
            compress: false,
            encrypt: false,
          ),
        ) {
    // pdfDocument.catalog.colorProfile = this;
  }

  @override
  void prepare() {
    super.prepare();
    // params['/N'] = const PdfNum(3);
    // params.data = icc;
  }
}
