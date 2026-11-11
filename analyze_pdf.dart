import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  final file = File(r'C:\Users\nikea\AndroidStudioProjects\seating_arrangement\FN-THEORY_1767841202.pdf');
  
  if (!await file.exists()) {
    print('PDF file not found');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final document = PdfDocument(inputBytes: bytes);
  
  print('PDF has ${document.pages.count} pages');
  
  final textExtractor = PdfTextExtractor(document);
  final fullText = textExtractor.extractText();
  
  print('Total text length: ${fullText.length} characters');
  
  // Show first 1000 characters
  print('\nFirst 1000 characters:');
  print(fullText.substring(0, fullText.length > 1000 ? 1000 : fullText.length));
  
  // Find all register number patterns
  final regNumbers = RegExp(r'\b\d{10,15}\b').allMatches(fullText);
  print('\nFound ${regNumbers.length} potential register numbers');
  
  // Show first 10 with context
  var count = 0;
  for (final match in regNumbers) {
    if (count++ >= 10) break;
    
    final start = match.start > 50 ? match.start - 50 : 0;
    final end = match.end + 50 < fullText.length ? match.end + 50 : fullText.length;
    final context = fullText.substring(start, end);
    
    print('\nRegister ${match.group(0)}:');
    print('Context: "$context"');
  }
  
  document.dispose();
}